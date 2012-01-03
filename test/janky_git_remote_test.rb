require File.expand_path("../test_helper", __FILE__)

class JankyGitRemoteTest < Test::Unit::TestCase
  def setup
    env = environment
    env["JANKY_GIT_SERVICE"] = "remote"
    env["JANKY_GITREMOTE_ROOT"] = "server:folder"

    Janky.setup(env)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)

    Janky::Campfire.rooms = {1 => "enterprise", 2 => "builds"}
    Janky::Campfire.default_room_name = "builds"

    hubot_setup("github/github")
  end

  test "hubot setup git remote" do
    assert hubot_setup("project").body.
      include?("server:folder/project")
  end
end