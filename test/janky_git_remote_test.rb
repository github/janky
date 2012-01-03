require File.expand_path("../test_helper", __FILE__)

class JankyGitRemoteTest < Test::Unit::TestCase
  def setup
    env = environment
    env["JANKY_GIT_SERVICE"] = "remote"
    env["JANKY_GIT_REMOTE_ROOT"] = "server:folder"

    Janky.setup(env)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)

    Janky::Campfire.rooms = {1 => "enterprise", 2 => "builds"}
    Janky::Campfire.default_room_name = "builds"

    hubot_setup("github/github")
  end

  test "hubot setup git remote" do
    assert_equal 'Setup project at server:folder/project | http://localhost:9393/project', hubot_setup("project").body
    assert_equal 'Setup pro-ect at server:folder/pro-ect | http://localhost:9393/pro-ect', hubot_setup("pro-ect").body
  end
end