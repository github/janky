require File.expand_path("../test_helper", __FILE__)

class CommitTest < Test::Unit::TestCase
  def setup
    Janky.setup(environment)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)
  end

  test "responds to #last_build" do
    assert_respond_to Janky::Commit.new, :last_build
  end

  test "responds to #build!" do
    assert_respond_to Janky::Commit.new, :build!
  end
end
