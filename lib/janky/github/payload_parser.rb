module Janky
  module GitHub
    class PayloadParser
      def initialize(json, legacy_payload = false)
        json = extract_json_from_legacy_data(json) if legacy_payload

        @payload = Yajl.load(json)
      end

      def head
        @payload["after"]
      end

      def compare
        @payload["compare"]
      end

      def commits
        @payload["commits"].map do |commit|
          GitHub::Commit.new(
            commit["id"],
            commit["url"],
            commit["message"],
            normalize_author(commit["author"]),
            commit["timestamp"]
          )
        end
      end

      def normalize_author(author)
        if email = author["email"]
          "#{author["name"]} <#{email}>"
        else
          author
        end
      end

      def uri
        if uri = @payload["uri"]
          return uri
        end

        repository = @payload["repository"]

        if repository["private"]
          "git@github.com:#{URI(repository["url"]).path[1..-1]}"
        else
          uri = URI(repository["url"])
          uri.scheme = "git"
          uri.to_s
        end
      end

      def branch
        @payload["ref"].split("refs/heads/").last
      end

      def extract_json_from_legacy_data(data)
        CGI::unescape(data.gsub(/^payload=/, ""))
      end
    end
  end
end
