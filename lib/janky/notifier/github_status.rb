module Janky
  module Notifier
    # Create GitHub Status updates for builds.
    #
    # Note that Statuses are immutable - so we create one for
    # "pending" status when a build starts, then create a new status for
    # "success" or "failure" when the build is complete.
    class GithubStatus
      # Initialize with an OAuth token to POST Statuses with
      def initialize(token, api_url)
        @token = token
        @api_url = URI(api_url)
      end

      # Create a Pending Status for the Commit when it starts.
      def started(build)
        repo   = build.repo_nwo
        path  = "repos/#{repo}/statuses/#{build.sha1}"

        post(path, "pending", build.web_url, "Build ##{build.number} started")
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

        post(path, status, build.web_url, desc)
      end

      # Internal: POST the new status to the API
      def post(path, status, url, desc)
        http = Net::HTTP.new(@api_url.host, @api_url.port)
        post = Net::HTTP::Post.new("#{@api_url.path}#{path}")

        http.use_ssl = true

        post["Content-Type"] = "application/json"
        post["Authorization"] = "token #{@token}"

        post.body = {
          :state => status,
          :target_url => url,
          :description => desc,
        }.to_json

        http.request(post)
      end
    end
  end
end
