require "file_utils"
require "placeos-log-backend"
require "placeos-models/spec/generator"
require "../src/placeos-frontends"
require "../lib/action-controller/spec/curl_context"
require "action-controller/server"

require "spec"

TEST_DIR = "test-www"

Spec.before_suite do
  Log.builder.bind "*", Log::Severity::Debug, PlaceOS::LogBackend.log_backend
  reset
end

ActionController::Server.before(
  ActionController::ErrorHandler.new(PlaceOS::Frontends::PROD, ["X-Request-ID"]),
  ActionController::LogHandler.new(ms: true)
)

Spec.after_suite { reset }

PlaceOS::Frontends::Loader.configure &.content_directory=(TEST_DIR)

def reset
  FileUtils.rm_rf(TEST_DIR)
end

def example_repository(
  uri : String = "https://github.com/placeos/backoffice",
  branch : String = "master"
)
  existing = PlaceOS::Model::Repository.where(folder_name: "backoffice").first?
  if existing
    unless existing.uri == uri && existing.branch == branch
      existing.uri = uri
      existing.branch = branch
    end

    existing
  else
    repository = PlaceOS::Model::Generator.repository(type: PlaceOS::Model::Repository::Type::Interface)
    repository.uri = uri
    repository.name = "Backoffice"
    repository.folder_name = "backoffice"
    repository.branch = branch
    repository
  end
end
