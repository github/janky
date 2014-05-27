module Janky
  module ChatService
    class Hubot
      def initialize(settings)
        @available_rooms = settings["JANKY_CHAT_HUBOT_ROOMS"]

        url = settings["JANKY_CHAT_HUBOT_URL"]
        if url.nil? || url.empty?
          raise Error, "JANKY_CHAT_HUBOT_URL setting is required"
        end
        @url = URI(url)
      end

      def speak(message, room, options = {:color => "yellow"})
        request(message, room)
      end

      def rooms
        @available_rooms.split(',').map do |room|
          id, name = room.strip.split(':')
          name ||= id
          Room.new(id, name)
        end
      end

      def request(message, room)
        uri  = @url
        user = uri.user
        pass = uri.password
        path = uri.path

        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == "https"
          http.use_ssl = true
        end

        post = Net::HTTP::Post.new("#{path}/janky")
        post.basic_auth(user, pass) if user && pass
        post["Content-Type"] = "application/json"
        post.body = {:message => message, :room => room}.to_json
        response = http.request(post)
        unless response.code == "200"
          Exception.push_http_response(response)
          raise Error, "Failed to notify"
        end
      end
    end
  end

  register_chat_service "hubot", ChatService::Hubot
end
