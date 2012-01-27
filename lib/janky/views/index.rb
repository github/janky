# encoding: UTF-8
module Janky
  module Views
    class Index < Layout
      def jobs
        @builds.collect do |build|
          {
            :console_path    => "/#{build.number}/output",
            :compare_url     => build.compare,
            :repo_path       => "/#{build.repo_name}",
            :branch_path     => "/#{build.repo_name}/#{build.branch_name}",
            :repo_name       => build.repo_name,
            :branch_name     => build.branch_name,
            :status          => css_status_for(build),
            :last_built_text => last_built_text_for(build),
            :message         => build.commit_message,
            :sha1            => build.sha1,
            :author          => build.commit_author
          }
        end
      end

      def css_status_for(build)
        if build.green?
          "good"
        elsif build.building?
          "building"
        else
          "janky"
        end
      end

      def last_built_text_for(build)
        if build.building?
          "Build started <span class='relatize'>#{build.started_at}</span>…"
        elsif build.completed?
          "Built in <span>#{build.duration}</span> seconds"
        end
      end
    end
  end
end
