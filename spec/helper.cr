require "spec"

require "file_utils"
require "placeos-models/spec/generator"

require "../src/frontends"

TEST_DIR = "test-www"

Spec.before_suite { reset }
Spec.after_suite { reset }

PlaceOS::Frontends::Loader.configure do |settings|
  settings.content_directory = TEST_DIR
end

def reset
  FileUtils.rm_rf(TEST_DIR)
end

def example_repository
  existing = PlaceOS::Model::Repository.where(folder_name: "hello-world").first?
  return existing if existing

  repository = PlaceOS::Model::Generator.repository(type: PlaceOS::Model::Repository::Type::Interface)
  repository.uri = "https://github.com/octocat/Hello-World"
  repository.name = "hello-world"
  repository.folder_name = "hello-world"
  repository.save!
end
