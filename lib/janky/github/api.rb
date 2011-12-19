module Janky
  module GitHub
    class API
      def initialize(user, password)
        @user     = user
        @password = password
      end

      def create(nwo, secret, url)
        request = Net::HTTP::Post.new("/repos/#{nwo}/hooks")
        payload = build_payload(url, secret)
        request.body = Yajl.dump(payload)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def trigger(hook_url)
        path    = URI(hook_url).path
        request = Net::HTTP::Post.new("#{path}/test")
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def get(hook_url)
        path    = URI(hook_url).path
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def repo_get(nwo)
        path    = "/repos/#{nwo}"
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def build_payload(url, secret)
        { "name"   => "web",
          "active" => true,
          "config" => {
            "url"          => url,
            "secret"       => secret,
            "content_type" => "json"
          }
        }
      end

      def http
        @http ||= http!
      end

      def http!
        uri  = URI("https://api.github.com")
        http = Net::HTTP.new(uri.host, uri.port)

        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_path     = "/etc/ssl/certs"

        http
      end
    end
  end
end
