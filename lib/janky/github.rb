module Janky
  module GitHub
    def self.setup(settings, user, password, secret, url, enterprise_host=nil)
      @user     = user
      @password = password
      @secret   = secret
      @url      = url

      if enterprise_host
        @apiurl  = "https://#{enterprise_host}/api/v3/"
        @gitroot = "git@#{enterprise_host}:"
      else
        @apiurl  = "https://api.github.com"
        @gitroot = "git@github.com:"
      end
    end

    class << self
      attr_reader :secret
      attr_reader :gitroot
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
      response = api.create(nwo, @secret, @url)

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
      @api ||= API.new(@user, @password, @apiurl)
    end
  end
end
