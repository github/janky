module Janky
  module Notifier
    class GithubPullRequestService

      def initialize(settings)
        @base_url = settings['JANKY_BASE_URL']
      end

      def completed(build)
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
              "#{@base_url}#{build.number}/output"
            ]

            GitHub.comment_issue(repo.github_owner, repo.github_name, pull_request['number'], message)
          end
        end
      end
    end
  end
end
