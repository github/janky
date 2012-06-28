module Janky
  module Notifier
    class GithubPullRequestService

      def initialize(settings)
        @settings = settings
      end

      def completed(build)
        post_comment(build) if enabled?
      end

      def post_comment(build)
        repo = build.commit.repository
        GitHub.pull_request_get(repo.github_owner, repo.github_name).map do |pull_request|
          if pull_request['head']['sha'] == build.sha1
            status = build.green? ? "was successful" : "failed"
            color = build.green? ? ":+1:" : ":-1:"

            message = "%s Build (%s) %s (%ss) %s" % [
              color,
              build.short_sha1,
              status,
              build.duration,
              "#{base_url}#{build.number}/output"
            ]

            GitHub.comment_issue(repo.github_owner, repo.github_name, pull_request['number'], message)
          end
        end
      end

      def base_url
        @settings['JANKY_BASE_URL']
      end

      def enabled?
        @settings["JANKY_ENABLE_PULL_REQUEST"] == "true"
      end
    end
  end
end
