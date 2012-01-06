$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "janky"
require "test/unit"
require "database_cleaner"

class Test::Unit::TestCase
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\s+/,'_')}".to_sym, block)
  end

  def environment
    { "RACK_ENV" => "test",
      "JANKY_CONFIG_DIR" => File.dirname(__FILE__),
      "JANKY_GITHUB_USER" => "hubot",
      "JANKY_GITHUB_OAUTH_TOKEN" => "token",
      "JANKY_GITHUB_HOOK_SECRET" => "secret",
      "JANKY_HUBOT_USER" => "hubot",
      "JANKY_HUBOT_PASSWORD" => "password",
      "JANKY_CAMPFIRE_ACCOUNT" => "github",
      "JANKY_CAMPFIRE_TOKEN" => "token",
      "JANKY_CHAT_DEFAULT_ROOM" => "Builds",
      "JANKY_CHAT_SERVICE" => "campfire"
    }
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

  def gh_payload(repo, branch, commits)
    head = commits.first

    Janky::GitHub::Payload.new(
      repo.uri,
      branch,
      head.sha1,
      commits,
      "http://github/compare/#{branch}...master"
    )
  end

  def get(path)
    Rack::MockRequest.new(Janky.app).get(path)
  end

  def gh_post_receive(repo_name, branch = "master", commit = "HEAD")
    repo    = Janky::Repository.find_by_name!(repo_name)
    payload = gh_payload(repo, branch, [gh_commit(commit)])
    digest  = OpenSSL::Digest::Digest.new("sha1")
    sig     = OpenSSL::HMAC.hexdigest(digest, Janky::GitHub.secret, payload.to_json)

    Rack::MockRequest.new(Janky.app).post("/_github",
      :input            => payload.to_json,
      "CONTENT_TYPE"    => "application/json",
      "HTTP_X_HUB_SIGNATURE" => "sha1=#{sig}"
    )
  end

  def gh_legacy_post_receive(repo_name, branch = "master", commit = "HEAD")
    repo    = Janky::Repository.find_by_name!(repo_name)
    payload = gh_payload(repo, branch, [gh_commit(commit)])
    legacy_payload = "payload=#{CGI::escape(payload.to_json)}"

    Rack::MockRequest.new(Janky.app).post("/_github",
      :input            => legacy_payload,
      "CONTENT_TYPE"    => "application/x-www-form-urlencoded",
    )
  end

  def hubot_setup(nwo, name = nil)
    hubot_request("POST", "/_hubot/setup", :params => {
      :nwo   => nwo,
      :name  => name
    })
  end

  def hubot_build(repo, branch, room_name = nil)
    params =
      if room_id = Janky::Chat.room_id(room_name)
        {"room_id" => room_id.to_s}
      else
        {}
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
