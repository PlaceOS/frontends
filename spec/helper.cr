require "spec"

require "file_utils"
require "placeos-models/spec/generator"

require "../src/placeos-frontends"

TEST_DIR = "test-www"

Spec.before_suite do
  Log.builder.bind "*", Log::Severity::Debug, PlaceOS::Frontends::LOG_BACKEND
  reset
end

Spec.after_suite { reset }

PlaceOS::Frontends::Loader.configure do |settings|
  settings.content_directory = TEST_DIR
end

def reset
  FileUtils.rm_rf(TEST_DIR)
end

def example_branched_repository(branch : String = "test")
  existing = PlaceOS::Model::Repository.where(folder_name: "ulid").first?
  if existing
    unless existing.branch == branch
      existing.branch = branch
      existing.save!
    end

    existing
  else
    repository = PlaceOS::Model::Generator.repository(type: PlaceOS::Model::Repository::Type::Interface)
    repository.uri = "https://github.com/place-labs/ulid"
    repository.name = "ulid"
    repository.folder_name = "ulid"
    repository.branch = branch

    repository.save!
  end
end

def example_repository(uri : String = "https://github.com/place-labs/backoffice-release")
  existing = PlaceOS::Model::Repository.where(folder_name: "backoffice").first?
  if existing
    unless existing.uri == uri
      existing.uri = uri
      existing.save!
    end

    existing
  else
    repository = PlaceOS::Model::Generator.repository(type: PlaceOS::Model::Repository::Type::Interface)
    repository.uri = uri
    repository.name = "Backoffice"
    repository.folder_name = "backoffice"
    repository.save!
  end
end
