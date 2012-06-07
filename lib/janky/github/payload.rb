module Janky
  module GitHub
    class Payload
      def self.parse(json)
        parsed = PayloadParser.new(json)
        new(parsed.uri, parsed.branch, parsed.head, parsed.pusher,
            parsed.commits,
            parsed.compare)
      end

      def initialize(uri, branch, head, pusher, commits, compare)
        @uri     = uri
        @branch  = branch
        @head    = head
        @pusher  = pusher
        @commits = commits
        @compare = compare
      end

      attr_reader :uri, :branch, :head, :pusher, :commits, :compare

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
