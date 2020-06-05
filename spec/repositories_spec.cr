require "./helper"

module PlaceOS::Frontends::Api
  describe Repositories do
    it "lists commits for a loaded repository" do
      repository = example_repository
      Api::Repositories.loader = Loader.new.start
      commits = Api::Repositories.commits?(repository.folder_name.as(String))
      commits.should_not be_nil
      commits.not_nil!.size.should be > 0
      Api::Repositories.loader.stop
    end

    it "lists current commit for all loaded repositories" do
      repository = example_repository
      Api::Repositories.loader = Loader.new.start
      loaded = Api::Repositories.loaded_repositories
      loaded.should be_a(Hash(String, String))
      loaded[repository.folder_name.as(String)]?.should_not be_nil
      loaded[repository.folder_name.as(String)].should_not eq("HEAD")
      Api::Repositories.loader.stop
    end
  end
end
