module Janky
  module GitHub
    class Commit
      def initialize(sha1, url, message, author, time)
        @sha1    = sha1
        @url     = url
        @message = message
        @author  = author
        @time    = time
      end

      attr_reader :sha1, :url, :message, :author

      def committed_at
        @time
      end

      def to_hash
        { :id        => @sha1,
          :url       => @url,
          :message   => @message,
          :author    => {:name => @author},
          :timestamp => @time }
      end
    end
  end
end
