module Janky
  module Notifier
    # Create GitHub Status updates for builds.
    #
    # Note that Statuses are immutable - so we create one for
    # "pending" status when a build starts, then create a new status for
    # "success" or "failure" when the build is complete.
    class GithubStatus
      # Initialize with an OAuth token to POST Statuses with
      def initialize(token, api_url, context = nil)
        @token = token
        @api_url = URI(api_url)
        @default_context = context
      end

      def context(build)
        repository_context(build.repository) || @default_context
      end

      def repository_context(repository)
        repository && repository.context
      end

      # Create a Pending Status for the Commit when it is queued.
      def queued(build)
        repo   = build.repo_nwo
        path  = "repos/#{repo}/statuses/#{build.sha1}"

        post(path, "pending", build.web_url, "Build ##{build.number} queued", context(build))
      end

      # Create a Pending Status for the Commit when it starts.
      def started(build)
        repo   = build.repo_nwo
        path  = "repos/#{repo}/statuses/#{build.sha1}"

        post(path, "pending", build.web_url, "Build ##{build.number} started", context(build))
      end

      # Create a Success or Failure Status for the Commit.
      def completed(build)
        repo   = build.repo_nwo
        path   = "repos/#{repo}/statuses/#{build.sha1}"
        status = build.green? ? "success" : "failure"

        desc = case status
          when "success" then "Build ##{build.number} succeeded in #{build.duration}s"
          when "failure" then "Build ##{build.number} failed in #{build.duration}s"
        end

        post(path, status, build.web_url, desc, context(build))
      end

      # Internal: POST the new status to the API
      def post(path, status, url, desc, context = nil)
        http = Net::HTTP.new(@api_url.host, @api_url.port)
        post = Net::HTTP::Post.new("#{@api_url.path}#{path}")

        http.use_ssl = true

        post["Content-Type"] = "application/json"
        post["Authorization"] = "token #{@token}"

        body = {
          :state => status,
          :target_url => url,
          :description => desc,
        }

        unless context.nil?
          post["Accept"] = "application/vnd.github.she-hulk-preview+json"
          body[:context] = context
        end

        post.body = body.to_json

        http.request(post)
      end
    end
  end
end
