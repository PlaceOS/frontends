require "./base"
require "../loader"

module PlaceOS::Frontends::Api
  class Repositories < Base
    base "/api/frontends/v1/repositories"
    Log = ::Log.for("frontends.api.repositories")

    class_property loader : Loader = Loader.instance

    # Returns an array of commits for a repository
    get "/:folder_name/commits", :commits do
      head :not_implemented
    end

    # Returns a hash of folder name to commits
    get "/", :loaded do
      head :not_implemented
    end
  end
end
