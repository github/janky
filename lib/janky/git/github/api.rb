module Janky
  module Git
    module GitHub
      class API
        def initialize(user, password, apiurl)
          @user     = user
          @password = password
          @apiurl   = apiurl
        end

        def create(nwo, secret, url)
          request = Net::HTTP::Post.new("/repos/#{nwo}/hooks")
          payload = build_payload(url, secret)
          request.body = Yajl.dump(payload)
          request.basic_auth(@user, @password)

          http.request(request)
        end

        def get_hook(hook_url)
          path    = URI(hook_url).path
          request = Net::HTTP::Get.new(path)
          request.basic_auth(@user, @password)

          http.request(request)
        end

        def repo_get(nwo)
          response = repo_get_response(nwo)

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

        def repo_get_response(nwo)
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
          uri  = URI(@apiurl)
          http = Net::HTTP.new(uri.host, uri.port)

          http.use_ssl     = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http.ca_path     = "/etc/ssl/certs"

          http
        end
      end
    end
  end
end