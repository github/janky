module Janky
  module Notifier
    class PullRequestBuildStatus
      def self.completed(build)
        if (pr_number = ::Janky::GitHub.get_pull_request_number(build.repo_nwo, build.branch_name))
          if build.green?
            ::Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":green_heart: @ #{build.sha1}")
          else
            ::Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":broken_heart: @ [#{build.short_sha1}](#{build.web_url})")
          end
        end
      end
    end
  end
end
