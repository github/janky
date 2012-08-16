module Janky
  module Notifier
    class PullRequestBuildStatus
      def self.completed(build)
        pr_number = Janky::GitHub.get_pull_request_number(build.repo_nwo, build.branch_name)

        if build.green?
          Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":green_heart:")
        else
          Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":exclamation:")
        end
      end
    end
  end
end
