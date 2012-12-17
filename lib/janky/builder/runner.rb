module Janky
  module Builder
    class Runner
      def initialize(base_url, build, adapter)
        @base_url = base_url
        @build    = build
        @adapter  = adapter
      end

      def run
        context_push
        @adapter.run(json_params, create_url)
      end

      def output
        context_push
        @adapter.output(output_url)
      end

      def json_params
        Yajl.dump(:parameter => [
          { :name => "JANKY_SHA1",       :value => @build.sha1 },
          { :name => "JANKY_BRANCH",     :value => @build.branch_name },
          { :name => "JANKY_ID",         :value => @build.id },
          { :name => "JANKY_COMMIT_URL", :value => @build.commit_url }
        ])
      end

      def output_url
        URI(@build.url + "consoleText")
      end

      def create_url
        URI("#{@base_url}job/#{@build.repo_job_name}/build")
      end

      def context_push
        Exception.push(
          :base_url   => @base_url.inspect,
          :build      => @build.inspect,
          :adapter    => @adapter.inspect,
          :params     => json_params.inspect,
          :create_url => create_url.inspect
        )
      end
    end
  end
end

