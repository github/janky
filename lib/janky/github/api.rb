module Janky
  module GitHub
    class API
      def initialize(url, user, password)
        @url = url
        @user = user
        @password = password
      end

      def create(nwo, secret, url)
        request = Net::HTTP::Post.new(build_path("repos/#{nwo}/hooks"))
        payload = build_payload(url, secret)
        request.body = Yajl.dump(payload)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def trigger(hook_url)
        path    = build_path(URI(hook_url).path + "/test")
        request = Net::HTTP::Post.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def get(hook_url)
        path    = build_path(URI(hook_url).path)
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def repo_get(nwo)
        path    = build_path("repos/#{nwo}")
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def branches(nwo)
        path    = build_path("repos/#{nwo}/branches")
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def commit(nwo, sha)
        path    = build_path("repos/#{nwo}/commits/#{sha}")
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def all_pull_requests(nwo)
        path    = build_path("repos/#{nwo}/pulls")
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def pull_request(nwo, number)
        path    = build_path("repos/#{nwo}/pull/#{number}")
        request = Net::HTTP::Get.new(path)
        request.basic_auth(@user, @password)

        http.request(request)
      end

      def comment_on_pull_request(nwo, pr_number, body)
        path    = build_path("repos/#{nwo}/issues/#{issue_number}/comments")
        request = Net::HTTP::Post.new(path)
        request.basic_auth(@user, @password)
        request.set_form_data('body' => body)

        http.request(request)
      end

      def build_path(path)
        if path[0] == ?/
          URI.join(@url, path[1..-1]).path
        else
          URI.join(@url, path).path
        end
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
        uri  = URI(@url)
        http = Net::HTTP.new(uri.host, uri.port)

        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_path     = "/etc/ssl/certs"

        http
      end
    end
  end
end
