require "./helper"

module PlaceOS::Frontends
  describe Loader do
    repository = example_repository
    repository_folder_name = repository.folder_name.as(String)

    Spec.before_each do
      reset
      repository = example_repository
    end

    it "loads frontends" do
      loader = Loader.new.start

      loader.processed.size.should eq 1

      Dir.exists?(File.join(TEST_DIR, repository_folder_name)).should be_true

      loader.stop
    end

    it "removes frontends" do
      loader = Loader.new.start

      loader.processed.size.should eq 1

      Dir.exists?(File.join(TEST_DIR, repository_folder_name)).should be_true

      repository.destroy
      sleep 0.5

      Dir.exists?(File.join(TEST_DIR, repository_folder_name)).should be_false

      loader.stop
    end
  end
end
