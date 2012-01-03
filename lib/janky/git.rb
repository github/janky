module Janky
  module Git
    class << self
      attr_accessor :service
      attr_accessor :registered_services
    end

    def self.setup(settings, url)
      desired = (settings["JANKY_GIT_SERVICE"] || 'github').downcase.to_sym
      if candidate_service = @registered_services.detect{ |k,v| k == desired}
        @service = candidate_service.last
        @service.setup(settings, url)
      else
        raise ArgumentError, "Invalid git service '#{desired}' requested. Valid values are: #{@registered_services.keys.join(', ')}"
      end

      @receiver = Receiver.new(settings)
    end

    def self.receiver
      @receiver
    end

    def self.repo_get(nwo, name = nil)
      @service.repo_get(nwo, name)
    end

    def self.find_or_create_hook(hook_url, repo_url)
      @service.find_or_create_hook(hook_url, repo_url)
    end
  end
end 