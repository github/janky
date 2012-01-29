module Janky
  module Views
    class Console < Layout
      def repo_name
        @build.repo_name
      end

      def repo_path
        "#{root}/#{repo_name}"
      end

      def branch_name
        @build.branch_name
      end

      def branch_path
        "#{repo_path}/#{branch_name}"
      end

      def status
        css_status_for(@build)
      end

      def commit_message
        @build.commit_message
      end

      def commit_url
        @build.commit_url
      end

      def commit_author
        @build.commit_author
      end

      def last_built_text
        last_built_text_for(@build)
      end

      def commit_short_sha
        @build.sha1
      end

      def output
        @build.output
      end
    end
  end
end
