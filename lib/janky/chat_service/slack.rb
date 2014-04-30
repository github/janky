require "slack-ruby"

module Janky
  module ChatService
    class Slack
      def initialize(settings)
        team = settings["JANKY_CHAT_SLACK_TEAM"]

        if team.nil? || team.empty?
          raise Error, "JANKY_CHAT_SLACK_TEAM setting is required"
        end

        token = settings["JANKY_CHAT_SLACK_TOKEN"]

        if token.nil? || token.empty?
          raise Error, "JANKY_CHAT_SLACK_TOKEN setting is required"
        end

        @client = ::SlackRuby::Client.new(team, token)
      end

      def speak(message, room_id, options = {})
        @client.post_message(room_id, message, options)
      end

      def rooms
        @rooms ||= @client.channels.map do |channel|
          Room.new(channel['id'], channel['name'])
        end
      end
    end
  end
end
