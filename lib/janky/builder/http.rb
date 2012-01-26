module Janky
  module Builder
    class HTTP
      def initialize(username, password)
        @username = username
        @password = password
      end

      def is_ssl?(url)
        url.scheme == "https"
      end

      def run(params, create_url)
        http     = Net::HTTP.new(create_url.host, create_url.port)
        http.use_ssl = is_ssl?(create_url)
        request  = Net::HTTP::Post.new(create_url.path)
        if @username && @password
          request.basic_auth(@username, @password)
        end
        request.form_data = {"json" => params}

        response = http.request(request)

        unless response.code == "302"
          Exception.push_http_response(response)
          raise Error, "Failed to create build"
        end
      end

      def output(url)
        http     = Net::HTTP.new(url.host, url.port)
        http.use_ssl = is_ssl?(url)
        request  = Net::HTTP::Get.new(url.path)
        if @username && @password
          request.basic_auth(@username, @password)
        end

        response = http.request(request)

        unless response.code == "200"
          Exception.push_http_response(response)
          raise Error, "Failed to get build output"
        end

        response.body
      end
    end
  end
end
