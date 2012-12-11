require File.expand_path("../test_helper", __FILE__)

class JankyTest < Test::Unit::TestCase
  def setup
    Janky.setup(environment)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)
  end

  test "job name is includes github owner and project" do
    repo = Janky::Repository.setup("github/janky")
    assert_match /\Agithub-janky-.+/, repo.job_name
  end

  test "github owner is parsed correctly" do
    repo = Janky::Repository.setup("github/janky")
    assert_equal "github", repo.github_owner
    assert_equal "janky", repo.github_name
  end

  test "owner with a dash is parsed correctly" do
    repo = Janky::Repository.setup("digital-science/central-ftp-manage")
    assert_equal "digital-science", repo.github_owner
    assert_equal "central-ftp-manage", repo.github_name
  end

  test "repository with period is parsed correctly" do
    repo = Janky::Repository.setup("github/pygments.rb")
    assert_equal "github", repo.github_owner
    assert_equal "pygments.rb", repo.github_name
  end
end
