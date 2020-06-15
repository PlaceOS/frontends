require "file_utils"
require "habitat"
require "placeos-compiler/drivers/git_commands"
require "placeos-core/resource"
require "placeos-models/repository"
require "tasker"

require "./constants"

module PlaceOS::Frontends
  class Loader < Core::Resource(Model::Repository)
    Log = ::Log.for("frontends.loader")
    private alias Result = Core::Resource::Result
    private alias Git = PlaceOS::Drivers::GitCommands

    Habitat.create do
      setting content_directory : String = ENV["PLACE_LOADER_WWW"]? || "www"
      setting update_crontab : String = ENV["PLACE_LOADER_CRON"]? || "0 * * * *"
      setting username : String? = ENV["PLACE_LOADER_GIT_USER"]?
      setting password : String? = ENV["PLACE_LOADER_GIT_PASS"]?
    end

    @@instace : Loader? = nil

    def self.instance
      @@instance ||= Loader.new(
        content_directory: settings.content_directory,
        username: settings.username,
        password: settings.password,
      )
    end

    getter content_directory : String
    getter username : String?
    private getter password : String?
    getter update_crontab : String
    private property update_cron : Tasker::CRON(Int32)? = nil

    def initialize(
      @content_directory : String = Loader.settings.content_directory,
      @update_crontab : String = Loader.settings.update_crontab,
      @username : String? = Loader.settings.username,
      @password : String? = Loader.settings.password
    )
      super()
    end

    def start
      create_base_www
      start_update_cron
      super
    end

    def stop
      update_cron.try &.cancel
      super
    end

    # Frontend loader implicitly and idempotently creates a base www
    protected def create_base_www
      content_directory_parent = Path[content_directory].parent.to_s
      Loader.clone_and_pull(
        repository_folder_name: content_directory,
        repository_uri: "https://github.com/PlaceOS/www-core",
        content_directory: content_directory_parent,
        username: username,
        password: password,
        depth: 1,
      )
    end

    protected def start_update_cron
      unless self.update_cron
        # Update the repositories periodically
        self.update_cron = Tasker.instance.cron(update_crontab) do
          repeating_update
        end
      end
    end

    protected def repeating_update
      # Pull all frontends
      loaded = load_resources

      # Pull www (content directory)
      pull_result = Git.pull(".", content_directory)
      unless pull_result[:exit_status] == 0
        Log.error { "failed to pull www: #{pull_result}" }
      end

      loaded
    end

    def process_resource(event) : Result
      repository = event[:resource]

      # Only consider Interface Repositories
      return Result::Skipped unless repository.repo_type == Model::Repository::Type::Interface

      case event[:action]
      when Action::Created, Action::Updated
        # Load the repository
        Loader.load(
          repository: repository,
          content_directory: @content_directory,
          username: @username,
          password: @password,
        )
      when Action::Deleted
        # Unload the repository
        Loader.unload(
          repository: repository,
          content_directory: @content_directory,
        )
      end.as(Result)
    rescue e
      # Add cloning errors
      model = event[:resource]
      raise Core::Resource::ProcessingError.new(model.name, "#{model.attributes} #{e.inspect_with_backtrace}")
    end

    def self.load(
      repository : Model::Repository,
      content_directory : String,
      username : String? = nil,
      password : String? = nil
    )
      content_directory = File.expand_path(content_directory)
      repository_folder_name = repository.folder_name.as(String)
      repository_uri = repository.uri.as(String)
      repository_commit = repository.commit_hash.as(String)

      repository_directory = File.expand_path(File.join(content_directory, repository_folder_name))

      # Clone and pull the repository
      clone_and_pull(
        repository_folder_name: repository_folder_name,
        repository_uri: repository_uri,
        content_directory: content_directory,
        username: username,
        password: password,
      )

      # Checkout repository to commit on the model
      checkout_commit(repository_directory, repository_commit)

      # Grab commit for the cloned/pulled repository
      current_commit = current_commit(repository_directory: repository_directory)

      if current_commit != repository_commit
        Log.info { {
          message:           "updating commit on Repository document",
          current_commit:    current_commit,
          repository_commit: repository_commit,
          folder_name:       repository_folder_name,
        } }

        # Refresh the repository model commit hash
        repository.update_fields(commit_hash: current_commit)
      end

      Log.info { {
        message:    "loaded repository",
        commit:     current_commit,
        repository: repository_folder_name,
        uri:        repository_uri,
      } }

      Result::Success
    end

    def self.current_commit(repository_directory : String, content_directory : String? = nil)
      path = content_directory.nil? ? repository_directory : File.join(content_directory, repository_directory)
      Git.repository_commits(path, count: 1).first[:commit]
    end

    def self.unload(
      repository : Model::Repository,
      content_directory : String
    )
      repository_folder_name = repository.folder_name.as(String)
      content_directory = File.expand_path(content_directory)
      repository_dir = File.expand_path(File.join(content_directory, repository_folder_name))

      # Ensure we `rmdir` a sane folder
      # - don't delete root
      # - don't delete working directory
      safe_directory = repository_dir.starts_with?(content_directory) &&
                       repository_dir != "/" &&
                       !repository_folder_name.empty? &&
                       !repository_folder_name.includes?("/") &&
                       !repository_folder_name.includes?(".")

      if !safe_directory
        Log.error { {
          message:           "attempted to delete unsafe directory",
          repository_folder: repository_folder_name,
        } }
        Result::Error
      else
        if Dir.exists?(repository_dir)
          begin
            FileUtils.rm_rf(repository_dir)
            Result::Success
          rescue
            Log.error { "failed to remove #{repository_dir}" }
            Result::Error
          end
        else
          Result::Skipped
        end
      end
    end

    # Set repository to a specific commit
    #
    def self.checkout_commit(repository_directory : String, commit : String = "HEAD")
      # Cannot checkout HEAD in a detached state
      commit = "master" if commit == "HEAD"

      result = Git.operation_lock(repository_directory).synchronize do
        ExecFrom.exec_from(repository_directory, "git", {"checkout", commit}, environment: {"GIT_TERMINAL_PROMPT" => "0"})
      end

      exit_code = result[:exit_code]
      raise "git checkout #{commit} failed with #{exit_code} in path #{repository_directory}: #{result[:output]}" if exit_code != 0
    end

    def self.clone_and_pull(
      repository_folder_name : String,
      repository_uri : String,
      content_directory : String,
      username : String? = nil,
      password : String? = nil,
      depth : Int32? = nil
    )
      Git.repo_lock(repository_folder_name).write do
        clone_result = Git.clone(repository_folder_name, repository_uri, username, password, content_directory, depth: depth)
        raise "failed to clone\n#{clone_result[:output]}" unless clone_result[:exit_status] == 0

        # Pull if already cloned and pull intended
        if clone_result[:output].includes?("already exists")
          pull_result = Git.pull(repository_folder_name, content_directory)
          raise "failed to pull\n#{pull_result}" unless pull_result[:exit_status] == 0
        end
      end
    end
  end
end
