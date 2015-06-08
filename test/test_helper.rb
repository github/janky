$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "janky"
require "test/unit"
require "mocha/setup"
require "database_cleaner"

class Test::Unit::TestCase
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\s+/,'_')}".to_sym, block)
  end

  def default_environment
    { "RACK_ENV" => "test",
      "JANKY_CONFIG_DIR" => File.dirname(__FILE__),
      "JANKY_GITHUB_USER" => "hubot",
      "JANKY_GITHUB_OAUTH_TOKEN" => "token",
      "JANKY_GITHUB_HOOK_SECRET" => "secret",
      "JANKY_HUBOT_USER" => "hubot",
      "JANKY_HUBOT_PASSWORD" => "password",
      "JANKY_CHAT_CAMPFIRE_ACCOUNT" => "github",
      "JANKY_CHAT_CAMPFIRE_TOKEN" => "token",
      "JANKY_CHAT_DEFAULT_ROOM" => "Builds",
      "JANKY_CHAT" => "campfire"
    }
  end

  def environment
    env = default_environment
    ENV.each do |key, value|
      if key =~ /^JANKY_/
        env[key] = value
      end
    end
    env
  end

  def gh_commit(sha1 = "HEAD")
    Janky::GitHub::Commit.new(
      sha1,
      "https://github.com/github/github/commit/#{sha1}",
      ":octocat:",
      "sr",
      Time.now
    )
  end

  def gh_payload(repo, branch, pusher, commits)
    head = commits.first

    Janky::GitHub::Payload.new(
      repo.uri,
      branch,
      head.sha1,
      pusher,
      commits,
      "http://github/compare/#{branch}...master"
    )
  end

  def get(path)
    Rack::MockRequest.new(Janky.app).get(path)
  end

  def gh_post_receive(repo_name, branch = "master", commit = "HEAD",
    pusher = "user")

    repo    = Janky::Repository.find_by_name!(repo_name)
    payload = gh_payload(repo, branch, pusher, [gh_commit(commit)])
    digest  = OpenSSL::Digest::SHA1.new
    sig     = OpenSSL::HMAC.hexdigest(digest, Janky::GitHub.secret,
                payload.to_json)

    Janky::GitHub.set_branch_head(repo.nwo, branch, commit)

    Rack::MockRequest.new(Janky.app).post("/_github",
      :input            => payload.to_json,
      "CONTENT_TYPE"    => "application/json",
      "HTTP_X_HUB_SIGNATURE" => "sha1=#{sig}"
    )
  end

  def hubot_setup(nwo, name = nil)
    hubot_request("POST", "/_hubot/setup", :params => {
      :nwo   => nwo,
      :name  => name
    })
  end

  def hubot_build(repo, branch, room_name = nil, user = nil)
    params =
      if room_id = Janky::ChatService.room_id(room_name)
        {"room_id" => room_id.to_s}
      else
        {}
      end

    if user
      params["user"] = user
    end

    hubot_request("POST", "/_hubot/#{repo}/#{branch}", :params => params)
  end

  def hubot_status(repo=nil, branch=nil)
    if repo && branch
      hubot_request("GET", "/_hubot/#{repo}/#{branch}")
    else
      hubot_request("GET", "/_hubot")
    end
  end

  def hubot_last(options = {})
    hubot_request "GET",
      "/_hubot/builds?limit=#{options[:limit]}&building=#{options[:building]}"
  end

  def hubot_latest_build_sha(repo, branch)
    response = hubot_status(repo, branch)
    Yajl.load(response.body).first["sha1"]
  end

  def hubot_request(method, path, opts={})
    auth = ["#{Janky::Hubot.username}:#{Janky::Hubot.password}"].pack("m*")
    env  = {"HTTP_AUTHORIZATION" => "Basic #{auth}"}

    Rack::MockRequest.new(Janky.app).request(method, path, env.merge(opts))
  end

  def hubot_toggle(repo)
    hubot_request("POST", "/_hubot/toggle/#{repo}")
  end

  def hubot_update_room(repo, room_name)
    hubot_request("PUT", "/_hubot/#{repo}", :params => {
      :room => room_name
    })
  end
end
