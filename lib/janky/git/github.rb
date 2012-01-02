module Janky
  module Git
    module GitHub

      def self.setup(settings, url)
        @user     = settings["JANKY_GITHUB_USER"]
        @password = settings["JANKY_GITHUB_PASSWORD"]
        @secret   = settings["JANKY_GITHUB_HOOK_SECRET"]
        @apiurl   = settings["JANKY_GITHUB_API_URL"] ||= "https://api.github.com"
        @url      = url
      end

      def self.enable_mock!
        @api = Mock.new(@user, @password)
      end

      class << self
        attr_reader :secret
      end

      def self.receiver
        @receiver ||= Receiver.new(@secret)
      end

      def self.repo_get(nwo, name)
        repo = api.repo_get(nwo)
        return if !repo

        uri    = repo["private"] ? repo["ssh_url"] : repo["git_url"]
        name ||= repo["name"]
        uri.gsub!(/\.git$/, "")

        return [name, uri]
      end

      def self.find_or_create_hook(hook_url, repo_url)
        if !hook_url || hook_exists?(hook_url)
          match = repo_url[/.*[\/:](\w+)\/([a-zA-Z0-9\-_]+)/]

          github_owner = match && $1
          github_name  = match && $2

          hook_create("#{github_owner}/#{github_name}")
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

      def self.hook_exists?(hook_url)
        api.get_hook(hook_url).code == "200"
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

      def self.api
        @api ||= API.new(@user, @password, @apiurl)
      end
    end
  end
end
