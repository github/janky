require File.expand_path("../test_helper", __FILE__)

class JankyTest < Test::Unit::TestCase
  def setup
    Janky.setup(environment)
    Janky.enable_mock!
    Janky.reset!

    DatabaseCleaner.clean_with(:truncation)

    Janky::ChatService.rooms = {1 => "enterprise", "2" => "builds"}
    Janky::ChatService.default_room_name = "builds"

    hubot_setup("github/github")
  end

  test "green build" do
    Janky::Builder.green!
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master")
  end

  test "fail build" do
    Janky::Builder.red!
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.failure?("github", "master")
  end

  test "pending build" do
    Janky::Builder.green!
    gh_post_receive("github")

    assert Janky::Notifier.empty?
    Janky::Builder.start!
    Janky::Builder.complete!
    assert Janky::Notifier.success?("github", "master")
  end

  test "builds multiple repo with the same uri" do
    Janky::Builder.green!
    hubot_setup("github/github", "fi")
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master")
    assert Janky::Notifier.success?("fi", "master")
  end

  test "notifies room that triggered the build" do
    Janky::Builder.green!
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master", "builds")

    hubot_build("github", "master", "enterprise")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master", "enterprise")
  end

  test "dup commit same branch" do
    Janky::Builder.green!
    gh_post_receive("github", "master", "sha1")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.notifications.shift

    gh_post_receive("github", "master", "sha1")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.notifications.empty?
  end

  test "dup commit different branch" do
    Janky::Builder.green!
    gh_post_receive("github", "master", "sha1")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.notifications.shift

    gh_post_receive("github", "issues-dashboard", "sha1")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.notifications.empty?
  end

  test "dup commit currently building" do
    Janky::Builder.green!
    gh_post_receive("github", "master", "sha1")
    Janky::Builder.start!

    gh_post_receive("github", "issues-dashboard", "sha1")

    Janky::Builder.complete!

    assert_equal 1, Janky::Notifier.notifications.size
    assert Janky::Notifier.success?("github", "master")
  end

  test "dup commit currently red" do
    Janky::Builder.red!
    gh_post_receive("github", "master", "sha1")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.notifications.shift

    gh_post_receive("github", "master", "sha1")

    assert Janky::Notifier.notifications.empty?
  end

  test "dup commit disabled repo" do
    hubot_setup("github/github", "fi")
    hubot_toggle("fi")
    gh_post_receive("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!
    Janky::Notifier.reset!

    hubot_build("fi", "master")
    Janky::Builder.start!
    Janky::Builder.complete!
    assert Janky::Notifier.success?("fi", "master")
  end

  test "web dashboard" do
    assert get("/").ok?
    assert get("/janky").not_found?

    gh_post_receive("github")
    assert get("/").ok?
    assert get("/github").ok?

    Janky::Builder.start!
    assert get("/").ok?

    Janky::Builder.complete!
    assert get("/").ok?
    assert get("/github").ok?

    assert get("/github/master").ok?
    assert get("/github/strato").ok?

    assert get("#{Janky::Build.last.id}/output").ok?
  end

  test "hubot setup" do
    Janky::GitHub.repo_make_private("github/github")
    assert hubot_setup("github/github").body.
      include?("git@github.com:github/github")

    Janky::GitHub.repo_make_public("github/github")
    assert hubot_setup("github/github").body.
      include?("git://github.com/github/github")

    assert_equal 1, hubot_status.body.split("\n").size

    hubot_setup("github/janky")
    assert_equal 2, hubot_status.body.split("\n").size

    Janky::GitHub.repo_make_unauthorized("github/enterprise")
    assert hubot_setup("github/enterprise").body.
      include?("Couldn't access github/enterprise")

    assert_equal 201, hubot_setup("janky").status
  end

  test "hubot toggle" do
    hubot_toggle("github")
    gh_post_receive("github", "master", "deadbeef")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.empty?

    hubot_toggle("github")
    gh_post_receive("github", "master", "cream")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master")
  end

  test "hubot status" do
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    status = hubot_status.body
    assert status.include?("github")
    assert status.include?("green")
    assert status.include?("builds")

    hubot_build("github", "master")
    assert hubot_status.body.include?("green")

    Janky::Builder.start!
    assert hubot_status.body.include?("building")

    hubot_setup("github/janky")
    assert hubot_status.body.include?("no build")

    hubot_setup("github/team")
    gh_post_receive("team")
    assert hubot_status.ok?
  end

  test "build user" do
    gh_post_receive("github", "master", "HEAD", "the dude")
    Janky::Builder.start!
    Janky::Builder.complete!

    response = hubot_status("github", "master")
    data = Yajl.load(response.body)
    assert_equal 1, data.size
    build = data[0]
    assert_equal "the dude", build["user"]

    hubot_build("github", "master", nil, "the boyscout")
    Janky::Builder.start!
    Janky::Builder.complete!

    response = hubot_status("github", "master")
    data = Yajl.load(response.body)
    assert_equal 2, data.size
    build = data[0]
    assert_equal "the boyscout", build["user"]
  end

  test "hubot status repo" do
    gh_post_receive("github")
    payload = Yajl.load(hubot_status("github", "master").body)
    assert_equal 1, payload.size
    build = payload[0]
    assert build["queued"]
    assert build["pending"]
    assert !build["building"]

    Janky::Builder.start!
    Janky::Builder.complete!
    hubot_build("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    payload = Yajl.load(hubot_status("github", "master").body)

    assert_equal 2, payload.size
  end

  test "hubot last 1 builds" do
    3.times do
      gh_post_receive("github", "master")
      Janky::Builder.start!
      Janky::Builder.complete!
    end

    assert_equal 1, Yajl.load(hubot_last(limit: 1).body).size
  end

  test "hubot lasts completed" do
    gh_post_receive("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert_equal 1, Yajl.load(hubot_last.body).size
  end

  test "hubot lasts building" do
    gh_post_receive("github", "master")
    Janky::Builder.start!
    assert_equal 1, Yajl.load(hubot_last(building: true).body).size
  end

  test "hubot build" do
    gh_post_receive("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert hubot_build("github", "rails3").not_found?
  end

  test "hubot build sha" do
    gh_post_receive("github", "master", 'deadbeef')
    gh_post_receive("github", "master", 'cafebabe')
    Janky::Builder.start!
    Janky::Builder.complete!

    assert_equal "cafebabe", hubot_latest_build_sha("github", "master")

    hubot_build("github", "deadbeef")
    Janky::Builder.start!
    Janky::Builder.complete!
    assert_equal "deadbeef", hubot_latest_build_sha("github", "master")
  end

  test "getting latest commit" do
    gh_post_receive("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert_not_equal "deadbeef", hubot_latest_build_sha("github", "master")

    Janky::GitHub.set_branch_head("github/github", "master", "deadbeef")
    hubot_build("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert_equal "deadbeef", hubot_latest_build_sha("github", "master")
    assert_equal "deadbeef", Janky::Build.last.sha1
    assert_equal "Test Author <test@github.com>", Janky::Build.last.commit_author
    assert_equal "Test Message", Janky::Build.last.commit_message
    assert_equal "https://github.com/github/github/commit/deadbeef", Janky::Build.last.commit_url
  end

  test "hubot rooms" do
    response = hubot_request("GET", "/_hubot/rooms")
    rooms    = Yajl.load(response.body)
    assert_equal ["builds", "enterprise"], rooms
  end

  test "hubot set room" do
    gh_post_receive("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!
    assert Janky::Notifier.success?("github", "master", "builds")

    Janky::Notifier.reset!

    hubot_update_room("github", "enterprise").ok?
    hubot_build("github", "master")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert Janky::Notifier.success?("github", "master", "enterprise")
  end

  test "hubot 404s" do
    assert hubot_status("janky", "master").not_found?
    assert hubot_build("janky", "master").not_found?
    assert hubot_build("github", "master").not_found?
  end

  test "build janky url" do
    gh_post_receive("github")
    Janky::Builder.start!
    Janky::Builder.complete!

    assert_equal "http://localhost:9393/1/output", Janky::Build.last.web_url

    build_page = Janky::Build.last.repo_job_name + "/" + Janky::Build.last.number + "/"
    assert_equal "http://localhost:8080/job/" + build_page, Janky::Build.last.url
  end
end
