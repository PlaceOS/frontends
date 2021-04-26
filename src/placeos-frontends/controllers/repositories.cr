require "placeos-compiler/git_commands"

require "./base"
require "../loader"

module PlaceOS::Frontends::Api
  class Repositories < Base
    base "/api/frontends/v1/repositories"
    Log = ::Log.for(self)

    private alias Git = PlaceOS::Compiler::GitCommands

    class_property loader : Loader = Loader.instance

    # Returns an array of commits for a repository
    get "/:folder_name/commits", :commits do
      count = (params["count"]? || 50).to_i
      folder_name = params["folder_name"]
      commits = Repositories.commits?(folder_name, count)
      head :not_found if commits.nil?

      render json: commits
    end

    # Returns an array of branches for a repository
    get "/:folder_name/branches", :branches do
      folder_name = params["folder_name"]
      branches = Repositories.branches?(folder_name)
      head :not_found if branches.nil?

      render json: branches
    end

    # Returns a hash of folder name to commits
    get "/", :loaded do
      render json: Repositories.loaded_repositories
    end

    # Generates a hash of currently loaded repositories and their current commit
    def self.loaded_repositories : Hash(String, String)
      content_directory = loader.content_directory
      Dir
        .entries(content_directory)
        .reject(/^\./)
        .select { |e|
          path = File.join(content_directory, e)
          File.directory?(path) && File.exists?(File.join(path, ".git"))
        }
        .each_with_object({} of String => String) { |folder_name, hash|
          hash[folder_name] = Loader.current_commit(repository_directory: folder_name, content_directory: content_directory)
        }
    end

    def self.branches?(folder_name : String) : Array(String)?
      path = File.expand_path(File.join(loader.content_directory, folder_name))
      if Dir.exists?(path)
        Git.repo_operation(path) do
          ExecFrom.exec_from(path, "git", {"fetch", "--all"}, environment: {"GIT_TERMINAL_PROMPT" => "0"})
          result = ExecFrom.exec_from(path, "git", {"branch", "-r"}, environment: {"GIT_TERMINAL_PROMPT" => "0"})
          if result[:exit_code].zero?
            result[:output]
              .to_s
              .lines
              .compact_map { |l| l.strip.lchop("origin/") unless l =~ /HEAD/ }
              .sort!
              .uniq!
          end
        end
      end
    end

    def self.commits?(folder_name : String, count : Int32 = 50) : Array(NamedTuple(commit: String, date: String, author: String, subject: String))?
      path = File.expand_path(File.join(loader.content_directory, folder_name))
      if Dir.exists?(path)
        Git.repository_commits(path, count)
      end
    end
  end
end
