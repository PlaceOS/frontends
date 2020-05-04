require "compiler/drivers/git_commands"

require "./base"
require "../loader"

module PlaceOS::Frontends::Api
  class Repositories < Base
    base "/api/frontends/v1/repositories"
    Log = ::Log.for("frontends.api.repositories")

    private alias Git = PlaceOS::Drivers::GitCommands

    class_property loader : Loader = Loader.instance

    # Returns an array of commits for a repository
    get "/:folder_name/commits", :commits do
      count = (params["count"]? || 50).to_i
      folder_name = params["folder_name"]
      commits = Repositories.commits?(folder_name, count)
      head :not_found if commits.nil?

      render json: commits
    end

    # Returns a hash of folder name to commits
    get "/", :loaded do
      render json: Repositories.loaded_repositories
    end

    # Generates a hash of currently loaded repositories and their current commit
    def self.loaded_repositories : Hash(String, String)
      content_directory = loader.content_directory
      loaded = Dir.entries(content_directory).reject(/^\./).each_with_object({} of String => String) do |folder_name, hash|
        hash[folder_name] = Loader.current_commit(content_directory, folder_name)
      end

      loaded
    end

    def self.commits?(folder_name : String, count : Int32 = 50) : Array(NamedTuple(commit: String, date: String, author: String, subject: String))?
      path = File.expand_path(File.join(loader.content_directory, folder_name))
      if Dir.exists?(path)
        Git.repository_commits(path, count)
      end
    end
  end
end
