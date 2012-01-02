module Janky
  module GitHub
    def self.setup(secret)
      @secret = secret
    end

    class << self
      attr_reader :secret
    end

    def self.receiver
      @receiver ||= Receiver.new(@secret)
    end
  end
end
