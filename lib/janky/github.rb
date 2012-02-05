module Janky
  module GitHub
    # Setup the GitHub API client and Post-Receive hook endpoint.
    #
    # user     - API user as a String.
    # password - API password as a String.
    # api_url  - GitHub API URL as a String. Requires a trailing slash.
    # hook_url - String URL handling Post-Receive requests.
    #
    # Returns nothing.
    def self.setup(user, password, secret, github_url, hook_url)
      @user = user
      @password = password
      @secret = secret
      @github_url = github_url
      @hook_url = hook_url
      @git_host = URI(github_url).host
    end

    class << self
      attr_reader :secret
      attr_reader :git_host
    end

    def self.enable_mock!
      @api = Mock.new(@user, @password)
    end

    def self.repo_make_private(nwo)
      api.make_private(nwo)
    end

    def self.repo_make_public(nwo)
      api.make_public(nwo)
    end

    def self.repo_make_unauthorized(nwo)
      api.make_unauthorized(nwo)
    end

    def self.receiver
      @receiver ||= Receiver.new(@secret)
    end

    def self.repo_get(nwo)
      response = api.repo_get(nwo)

      case response.code
      when "200"
        Yajl.load(response.body)
      when "403", "404"
        nil
      else
        Exception.push_http_response(response)
        raise Error, "Failed to get hook"
      end
    end

    def self.hook_create(nwo)
      response = api.create(nwo, @secret, @hook_url)

      if response.code == "201"
        Yajl.load(response.body)["url"]
      else
        Exception.push_http_response(response)
        raise Error, "Failed to create hook"
      end
    end

    def self.hook_exists?(url)
      api.get(url).code == "200"
    end

    def self.api
      @api ||= API.new(@github_url, @user, @password)
    end
  end
end
