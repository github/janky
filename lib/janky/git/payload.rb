module Janky
  module Git
      class Payload
        def self.parse(json)
          parsed = PayloadParser.new(json)
          new(parsed.uri, parsed.branch, parsed.head, parsed.commits, parsed.compare)
        end

        def initialize(uri, branch, head, commits, compare)
          @uri     = uri
          @branch  = branch
          @head    = head
          @commits = commits
          @compare = compare
        end

        attr_reader :uri, :branch, :head, :commits, :compare

        def head_commit
          @commits.detect do |commit|
            commit.sha1 == @head
          end
        end

        def to_json
          { :after   => @head,
            :ref     => "refs/heads/#{@branch}",
            :uri     => @uri,
            :commits => @commits,
            :compare => @compare }.to_json
        end
      end
  end
end
