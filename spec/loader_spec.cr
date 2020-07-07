require "./helper"

module PlaceOS::Frontends
  describe Loader do
    repository = example_repository
    repository_folder_name = repository.folder_name.as(String)

    Spec.before_each do
      reset
      repository = example_repository
    end

    it "implicity loads www base" do
      loader = Loader.new.start

      Dir.exists?(File.join(TEST_DIR, "login")).should be_true

      loader.stop
    end

    it "loads frontends" do
      loader = Loader.new.start

      Dir.exists?(File.join(TEST_DIR, repository_folder_name)).should be_true

      loader.stop
    end

    it "removes frontends" do
      loader = Loader.new.start

      expected_path = File.join(TEST_DIR, repository_folder_name)

      Dir.exists?(expected_path).should be_true

      repository.destroy
      sleep 0.5

      Dir.exists?(expected_path).should be_false

      loader.stop
    end

    it "supports changing a uri" do
      loader = Loader.new.start

      expected_path = File.join(TEST_DIR, repository_folder_name)
      expected_uri = "https://github.com/place-labs/backoffice-alpha"

      Dir.exists?(expected_path).should be_true

      repository.uri = expected_uri
      repository.save!
      after_load = loader.processed.size
      while loader.processed.size == after_load
        Fiber.yield
      end

      Dir.exists?(expected_path).should be_true
      url = ExecFrom.exec_from(expected_path, "git", {"remote", "get-url", "origin"})[:output].to_s

      url.strip.should end_with("backoffice-alpha")

      loader.stop
    end

    describe "branches" do
      it "loads a specific branch" do
        repository = example_branched_repository("test")

        loader = Loader.new.start
        path = File.join(TEST_DIR, "ulid")

        Dir.exists?(path).should be_true
        Compiler::GitCommands.current_branch(path).should eq "test"

        loader.stop
      end

      it "switches branches" do
        repository = example_branched_repository("test")

        loader = Loader.new.start
        path = File.join(TEST_DIR, "ulid")

        Dir.exists?(path).should be_true
        Compiler::GitCommands.current_branch(path).should eq "test"

        repository.branch = "master"
        repository.save!

        after_load = loader.processed.size
        while loader.processed.size == after_load
          Fiber.yield
        end

        Dir.exists?(path).should be_true
        Compiler::GitCommands.current_branch(path).should eq "master"

        loader.stop
      end
    end
  end
end
