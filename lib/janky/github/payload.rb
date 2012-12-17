module Janky
  module GitHub
    class Payload
      def self.parse(json)
        new(PayloadParser.new(json))
      end

      def set_pull_request_commits(commits)
        @parsed.set_pull_request_commits(commits)
        @commits = @parsed.commits
      end

      def initialize(parsed)
        @parsed         = parsed
        @uri            = parsed.uri
        @branch         = parsed.branch
        @head           = parsed.head
        @pusher         = parsed.pusher
        @commits        = parsed.commits
        @compare        = parsed.compare
        @pull_request   = parsed.pull_request?
        @nwo            = parsed.nwo
        @pull_number    = parsed.pull_number
        @pull_action    = parsed.pull_action
      end

      attr_reader :uri, :branch, :head, :pusher, :commits, :compare,
        :pull_request, :nwo, :pull_number, :pull_action

      def head_commit
        @commits.detect do |commit|
          commit.sha1 == @head
        end
      end

      def to_json
        { :after   => @head,
          :ref     => "refs/heads/#{@branch}",
          :pusher  => {:name => @pusher},
          :uri     => @uri,
          :commits => @commits,
          :compare => @compare }.to_json
      end
    end
  end
end
