require "slack"

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

        @client = ::Slack::Client.new(team: team, token: token)
      end

      def speak(message, room_id, options = {})
        @client.post_message(message, room_id, options)
      end

      def rooms
        @rooms ||= @client.channels.map do |channel|
          Room.new(channel['id'], channel['name'])
        end
      end
    end
  end

  register_chat_service "slack", ChatService::Slack
end
