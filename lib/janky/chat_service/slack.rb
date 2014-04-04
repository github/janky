module Janky
    module ChatService
        class Slack
            attr_accessor :token, :default_room, :slack_url
            def initialize(settings)
                @token = settings["JANKY_CHAT_SLACK_TOKEN"]
		@default_room = settings["JANKY_CHAT_SLACK_ROOM"]
		@slack_url = settings["JANKY_CHAT_SLACK_URL"]
		@room = {}
            end

            def speak(message, room_id, opts={})
                uri = URI.parse(@slack_url)
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                request = Net::HTTP::Post.new("/services/hooks/slackbot?token=#{@token}&channel=%23#{@default_room}")
                request.body = message
                http.request(request)
            end

            def rooms
	      @rooms = {}
            end
        end
    end
    register_chat_service "slack", ChatService::Slack
end

