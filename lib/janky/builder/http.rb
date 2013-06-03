module Janky
  module Builder
    class HTTP
      def initialize(username, password)
        @username = username
        @password = password
      end

      def run(params, create_url)
        http     = Net::HTTP.new(create_url.host, create_url.port)
        if create_url.scheme == "https"
          http.use_ssl = true
        end

        request  = Net::HTTP::Post.new(create_url.path)
        if @username && @password
          request.basic_auth(@username, @password)
        end
        request.form_data = {"json" => params}

        response = http.request(request)

        if response.code != "302"
          Exception.push_http_response(response)
          raise Error, "Failed to create build"
        end
      end

      def stop(stop_url)
        http     = Net::HTTP.new(stop_url.host, stop_url.port)
        if stop_url.scheme == "https"
          http.use_ssl = true
        end

        request  = Net::HTTP::Post.new(stop_url.path)
        if @username && @password
          request.basic_auth(@username, @password)
        end

        response = http.request(request)

        if response.code != "302"
          Exception.push_http_response(response)
          raise Error, "Failed to stop build"
        end
      end

      def output(url)
        http     = Net::HTTP.new(url.host, url.port)
        if url.scheme == "https"
          http.use_ssl = true
        end

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
