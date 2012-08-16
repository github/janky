module Janky
  module Notifier
    module GitHub
      class PullRequestBuildStatus
        def self.completed(build)
         if build.green?
           Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":green_heart:")
         else
           Janky::GitHub.comment_on_pull_request(build.repo_nwo, pr_number, ":exclamation:")
         end
        end
      end
    end
  end
end
