module Janky
  module GitHub
    class PayloadParser
      def initialize(json)
        @payload = Yajl.load(json)
      end

      def pull_request?
        @payload.has_key?('pull_request')
      end

      def pull_number
        if @payload.has_key?('number')
          @payload['number']
        end
      end

      def pull_action
        if @payload.has_key?('action')
          @payload['action']
        end
      end

      def pusher
        if pull_request?
          @payload["sender"]["login"]
        else
          @payload["pusher"]["name"]
        end
      end

      def head
        if pull_request?
          @payload["pull_request"]["head"]["sha"]
        else
          @payload["after"]
        end
      end

      def base
        if pull_request?
          @payload["pull_request"]["base"]["sha"]
        else
          @payload["before"]
        end
      end

      def compare
        if pull_request?
          #HACK: event only has template in API style
          @payload["pull_request"]["head"]["repo"]["compare_url"]
            .gsub('//api.github.com/', '//github.com/')
            .gsub('/repos/', '/')
            .gsub('/commits/', '/commit/')
            .gsub('{base}', base[0..11])
            .gsub('{head}', head[0..11])
        else
          @payload["compare"]
        end
      end

      def set_pull_request_commits(commits)
        @payload["commits"] = commits
      end

      def commits
        if pull_request?
          map_pull_request_commits(@payload["commits"] || [])
        else
          map_merge_commits(@payload["commits"])
        end
      end

      def map_merge_commits(hash)
        hash.map do |commit|
          GitHub::Commit.new(
            commit["id"],
            commit["url"],
            commit["message"],
            normalize_author(commit["author"]),
            commit["timestamp"]
          )
        end
      end

      def map_pull_request_commits(hash)
        head_nwo = @payload["pull_request"]["head"]["repo"]["full_name"]
        base_nwo = @payload["pull_request"]["base"]["repo"]["full_name"]
        hash.map do |commit|
          # HACK: because GitHub keeps messing with the API results
          details = commit["commit"] || commit
          GitHub::Commit.new(
            commit["sha"],
            #HACK: event only has an API style url
            commit["url"]
              .gsub('//api.github.com/', '//github.com/')
              .gsub('/repos/', '/')
              .gsub('/commits/', '/commit/')
              .gsub(base_nwo, head_nwo),
            details["message"],
            normalize_author(details["author"]),
            details["author"]["date"]
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

      def nwo
        repository = @payload["repository"]
        if pull_request?
          owner = repository["owner"]["login"]
        else
          owner = repository["owner"]["name"]
        end

        "#{owner}/#{repository["name"]}"
      end

      def uri
        if uri = @payload["uri"]
          return uri
        end

        if pull_request?
          repository = @payload["repository"]
          if repository["private"]
            repository["ssh_url"].gsub(/\.git$/, '')
          else
            repository["git_url"].gsub(/\.git$/, '')
          end
        else
          repository = @payload["repository"]
          if repository["private"]
            "git@#{GitHub.git_host}:#{URI(repository["url"]).path[1..-1]}"
          else
            uri = URI(repository["url"])
            uri.scheme = "git"
            uri.to_s
          end
        end
      end

      def branch
        if pull_request?
          @payload["pull_request"]["head"]["ref"]
        else
          @payload["ref"].split("refs/heads/").last
        end
      end
    end
  end
end
