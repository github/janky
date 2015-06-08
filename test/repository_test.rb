require File.expand_path("../test_helper", __FILE__)

class RepositoryTest < Test::Unit::TestCase
  def setup
    Janky.setup(environment)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)
  end

  test "job name includes repo name" do
    repo = Janky::Repository.setup("github/janky")
    assert_match /\Ajanky-.+/, repo.job_name
  end

  test "job name includes custom name" do
    repo = Janky::Repository.setup("github/janky", "janky2")
    assert_match /\Ajanky2-.+/, repo.job_name
  end

  test "job name includes truncated MD5 digest" do
    repo = Janky::Repository.setup("github/janky")
    assert_match /-[0-9a-f]{12}$/, repo.job_name
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

  test "raises if there is no job config" do
    repo = Janky::Repository.setup("github/pygments.rb")
    # ensure we get file not found for job configs
    Janky.stubs(:jobs_config_dir).returns(Pathname("/tmp/"))
    assert_raise(Janky::Error) do
      puts repo.job_config_path
      repo.job_config_path
    end
  end

  test "default job config is selected if none provided" do
    repo = Janky::Repository.setup("github/pygments.rb", "pygments")
    assert_nil repo.job_template
    assert_match /default\.xml\.erb/, repo.job_config_path.to_s
  end

  test "custom job config is stored" do
    repo = Janky::Repository.setup("github/pygments.rb", "pygments", "custom")
    assert_equal "custom", repo.job_template
  end

  test "custom job config path is calculated" do
    repo = Janky::Repository.setup("github/pygments.rb", "pygments", "custom")
    assert_equal "custom", repo.job_template
    assert_match /custom\.xml\.erb/, repo.job_config_path.to_s
  end

end
