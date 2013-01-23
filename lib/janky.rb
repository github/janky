if RUBY_VERSION < "1.9.3"
  warn "Support for Ruby versions lesser than 1.9.3 is deprecated and will be " \
    "removed in Janky 1.0."
end

require "net/http"
require "digest/md5"

require "active_record"
require "replicate"
require "sinatra/base"
require "mustache/sinatra"
require "yajl"
require "yajl/json_gem"
require "tilt"
require "broach"
require "sinatra/auth/github"

require "janky/repository"
require "janky/branch"
require "janky/commit"
require "janky/build"
require "janky/build_request"
require "janky/github"
require "janky/github/api"
require "janky/github/mock"
require "janky/github/payload"
require "janky/github/commit"
require "janky/github/payload_parser"
require "janky/github/receiver"
require "janky/job_creator"
require "janky/helpers"
require "janky/hubot"
require "janky/builder"
require "janky/builder/client"
require "janky/builder/runner"
require "janky/builder/http"
require "janky/builder/mock"
require "janky/builder/payload"
require "janky/builder/receiver"
require "janky/chat_service"
require "janky/chat_service/campfire"
require "janky/chat_service/mock"
require "janky/exception"
require "janky/notifier"
require "janky/notifier/chat_service"
require "janky/notifier/mock"
require "janky/notifier/multi"
require "janky/notifier/github_status"
require "janky/app"
require "janky/views/layout"
require "janky/views/index"
require "janky/views/console"

# This is Janky, a continuous integration server. Checkout the 'app'
# method on this module for an overview of the different components
# involved.
module Janky
  # The base exception class raised when errors are encountered.
  class Error < StandardError; end

  # Setup the application, including the database and Jenkins connections.
  #
  # settings - Hash of app settings. Typically ENV but any object that responds
  #            to #[], #[]= and #each is valid. See required_settings for
  #            required keys. The RACK_ENV key is always required.
  #
  # Raises an Error when required settings are missing.
  # Returns nothing.
  def self.setup(settings)
    env = settings["RACK_ENV"]
    if env.nil? || env.empty?
      raise Error, "RACK_ENV is required"
    end

    required_settings.each do |setting|
      next if !settings[setting].nil? && !settings[setting].empty?

      if env == "production"
        raise Error, "#{setting} setting is required"
      end
    end

    if env != "production"
      settings["DATABASE_URL"] ||= "mysql2://root@localhost/janky_#{env}"
      settings["JANKY_BASE_URL"] ||= "http://localhost:9393/"
      settings["JANKY_BUILDER_DEFAULT"] ||= "http://localhost:8080/"
      settings["JANKY_CONFIG_DIR"] ||= File.dirname(__FILE__)
      settings["JANKY_CHAT"] ||= "campfire"
      settings["JANKY_CHAT_CAMPFIRE_ACCOUNT"] ||= "account"
      settings["JANKY_CHAT_CAMPFIRE_TOKEN"] ||= "token"
    end

    database = URI(settings["DATABASE_URL"])
    adapter  = database.scheme == "postgres" ? "postgresql" : database.scheme
    if settings["JANKY_BASE_URL"][-1] != ?/
      warn "JANKY_BASE_URL must have a trailing slash"
      settings["JANKY_BASE_URL"] = settings["JANKY_BASE_URL"] + "/"
    end
    base_url = URI(settings["JANKY_BASE_URL"]).to_s
    Build.base_url = base_url

    connection = {
      :adapter   => adapter,
      :host      => database.host,
      :database  => database.path[1..-1],
      :username  => database.user,
      :password  => database.password,
      :reconnect => true,
    }
    if socket = settings["JANKY_DATABASE_SOCKET"]
      connection[:socket] = socket
    end
    ActiveRecord::Base.establish_connection(connection)

    self.jobs_config_dir = config_dir = Pathname(settings["JANKY_CONFIG_DIR"])
    if !config_dir.directory?
      raise Error, "#{config_dir} is not a directory"
    end

    # Setup the callback URL of this Janky host.
    Janky::Builder.setup(base_url + "_builder")

    # Setup the default Jenkins build host
    if settings["JANKY_BUILDER_DEFAULT"][-1] != ?/
      raise Error, "JANKY_BUILDER_DEFAULT must have a trailing slash"
    end
    Janky::Builder[:default] = settings["JANKY_BUILDER_DEFAULT"]

    if settings.key?("JANKY_GITHUB_API_URL")
      api_url  = settings["JANKY_GITHUB_API_URL"]
      git_host = URI(api_url).host
    else
      api_url = "https://api.github.com/"
      git_host = "github.com"
    end
    if api_url[-1] != ?/
      raise Error, "JANKY_GITHUB_API_URL must have a trailing slash"
    end
    hook_url = base_url + "_github"
    valid_events = ['pull_request', 'push']
    if settings.key?("JANKY_GITHUB_EVENT_TYPES")
      events = settings["JANKY_GITHUB_EVENT_TYPES"].split(',') \
        .each { |e| e.strip! }
    else
      events = valid_events
    end
    extra = events.select { |e| !valid_events.include?(e) }
    if events.nil? or events.empty? or !extra.empty?
      raise Error, "JANKY_GITHUB_EVENT_TYPES must have #{valid_events.join(' or ')}"
    end
    Janky::GitHub.setup(
      settings["JANKY_GITHUB_USER"],
      settings["JANKY_GITHUB_PASSWORD"],
      settings["JANKY_GITHUB_HOOK_SECRET"],
      events,
      hook_url,
      api_url,
      git_host
    )

    if settings.key?("JANKY_SESSION_SECRET")
      Janky::App.register Sinatra::Auth::Github
      Janky::App.set({
        :sessions => true,
        :session_secret => settings["JANKY_SESSION_SECRET"],
        :github_team_id => settings["JANKY_AUTH_TEAM_ID"],
        :github_organization => settings["JANKY_AUTH_ORGANIZATION"],
        :github_options => {
          :secret => settings["JANKY_AUTH_CLIENT_SECRET"],
          :client_id => settings["JANKY_AUTH_CLIENT_ID"],
          :scopes => "repo",
        },
      })
    end

    Janky::Hubot.set(
      :base_url => settings["JANKY_BASE_URL"],
      :username => settings["JANKY_HUBOT_USER"],
      :password => settings["JANKY_HUBOT_PASSWORD"]
    )

    Janky::Exception.setup(Janky::Exception::Logger.new($stderr))

    if campfire_account = settings["JANKY_CAMPFIRE_ACCOUNT"]
      warn "JANKY_CAMPFIRE_ACCOUNT is deprecated. Please use " \
        "JANKY_CHAT_CAMPFIRE_ACCOUNT instead."
      settings["JANKY_CHAT_CAMPFIRE_ACCOUNT"] ||=
        settings["JANKY_CAMPFIRE_ACCOUNT"]
    end

    if campfire_token = settings["JANKY_CAMPFIRE_TOKEN"]
      warn "JANKY_CAMPFIRE_TOKEN is deprecated. Please use " \
        "JANKY_CHAT_CAMPFIRE_TOKEN instead."
      settings["JANKY_CHAT_CAMPFIRE_TOKEN"] ||=
        settings["JANKY_CAMPFIRE_TOKEN"]
    end

    chat_name = settings["JANKY_CHAT"] || "campfire"
    chat_settings = {}
    settings.each do |key, value|
      if key =~ /^JANKY_CHAT_#{chat_name.upcase}_/
        chat_settings[key] = value
      end
    end
    chat_room = settings["JANKY_CHAT_DEFAULT_ROOM"] ||
      settings["JANKY_CAMPFIRE_DEFAULT_ROOM"]
    if settings["JANKY_CAMPFIRE_DEFAULT_ROOM"]
      warn "JANKY_CAMPFIRE_DEFAULT_ROOM is deprecated. Please use " \
        "JANKY_CHAT_DEFAULT_ROOM instead."
    end
    ChatService.setup(chat_name, chat_settings, chat_room)

    if token = settings["JANKY_GITHUB_STATUS_TOKEN"]
      Notifier.setup([
        Notifier::GithubStatus.new(token, api_url),
        Notifier::ChatService
      ])
    else
      Notifier.setup(Notifier::ChatService)
    end
  end

  # List of settings required in production.
  #
  # Returns an Array of Strings.
  def self.required_settings
    %w[RACK_ENV DATABASE_URL
      JANKY_BASE_URL
      JANKY_BUILDER_DEFAULT
      JANKY_CONFIG_DIR
      JANKY_GITHUB_USER JANKY_GITHUB_PASSWORD JANKY_GITHUB_HOOK_SECRET
      JANKY_HUBOT_USER JANKY_HUBOT_PASSWORD]
  end

  class << self
    # Directory where Jenkins job configuration templates are located.
    #
    # Returns the directory as a Pathname.
    attr_accessor :jobs_config_dir
  end

  # Mock out all network-dependant components. Must be called after setup.
  # Typically used in test environments.
  #
  # Returns nothing.
  def self.enable_mock!
    Janky::Builder.enable_mock!
    Janky::GitHub.enable_mock!
    Janky::Notifier.enable_mock!
    Janky::ChatService.enable_mock!
    Janky::App.disable :github_team_id
  end

  # Reset the state of the mocks.
  #
  # Returns nothing.
  def self.reset!
    Janky::Notifier.reset!
    Janky::Builder.reset!
  end

  # The Janky Rack application, assembled from four apps. Exceptions raised
  # during the request cycle are caught by the Exception middleware which
  # typically reports them to an external service before re-raising the
  # exception.
  #
  # Returns a memoized Rack application.
  def self.app
    @app ||= Rack::Builder.app {
      # Exception reporting middleware.
      use Janky::Exception::Middleware

      # GitHub Post-Receive requests.
      map "/_github" do
        run Janky::GitHub.receiver
      end

      # Jenkins callback requests.
      map "/_builder" do
        run Janky::Builder.receiver
      end

      # Hubot API, protected by Basic Auth.
      map "/_hubot" do
        use Rack::Auth::Basic do |username, password|
          username == Janky::Hubot.username &&
            password == Janky::Hubot.password
        end

        run Janky::Hubot
      end

      # Web dashboard
      map "/" do
        run Janky::App
      end
    }
  end

  # Register a Chat service implementation.
  #
  # name    - Service name as a String, e.g. "irc".
  # service - Constant for the implementation.
  #
  # Returns nothing.
  def self.register_chat_service(name, service)
    Janky::ChatService.adapters[name] = service
  end

  register_chat_service "campfire", ChatService::Campfire
end
