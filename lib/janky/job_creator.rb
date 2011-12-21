module Janky
  class JobCreator
    def initialize(server_url, callback_url)
      @server_url   = server_url
      @callback_url = callback_url
    end

    def run(name, uri, template_path)
      creator.run(name, uri, template_path)
    end

    def creator
      @creator ||= Creator.new(HTTP, @server_url, @callback_url)
    end

    def enable_mock!
      @creator = Creator.new(Mock.new, @server_url, @callback_url)
    end

    class Creator
      def initialize(adapter, server_url, callback_url)
        @adapter      = adapter
        @server_url   = server_url
        @callback_url = callback_url
      end

      def run(name, uri, template_path)
        template = Tilt.new(template_path.to_s)
        config   = template.render(Object.new, {
          :name         => name,
          :repo         => uri,
          :callback_url => @callback_url
        })

        exception_context(config, name, uri)

        if !@adapter.exists?(@server_url, name)
          @adapter.run(@server_url, name, config)
          true
        end
      end

      def exception_context(config, name, uri)
        Exception.push(
          :server_url   => @server_url.inspect,
          :callback_url => @callback_url.inspect,
          :adapter      => @adapter.inspect,
          :config       => config.inspect,
          :name         => name.inspect,
          :repo         => uri.inspect
        )
      end
    end

    class Mock
      def run(server_url, name, config)
        name   || raise(Error, "no name")
        config || raise(Error, "no config")
        (URI === server_url) || raise(Error, "server_url is not a URI")

        true
      end

      def exists?(server_url, name)
        false
      end
    end

    class HTTP
      def self.exists?(server_url, name)
        uri  = server_url
        user = uri.user
        pass = uri.password
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl=true if (uri.scheme.casecmp("https") == 0)
        get = Net::HTTP::Get.new("/job/#{name}/")
        get.basic_auth(user, pass) if user && pass
        response = http.request(get)

        case response.code
        when "200"
          true
        when "404"
          false
        else
          Exception.push_http_response(response)
          raise "Failed to determine job existance"
        end
      end

      def self.run(server_url, name, config)
        uri  = server_url
        user = uri.user
        pass = uri.password
        http = Net::HTTP.new(uri.host, uri.port)

        post = Net::HTTP::Post.new("/createItem?name=#{name}")
        post.basic_auth(user, pass) if user && pass
        post["Content-Type"] = "application/xml"
        post.body = config

        response = http.request(post)

        unless response.code == "200"
          Exception.push_http_response(response)
          raise Error, "Failed to create job"
        end
      end
    end
  end
end
