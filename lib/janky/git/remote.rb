module Janky
  module Git
    module Remote
      def self.setup(settings, url)
        @gitroot = settings["JANKY_GITREMOTE_ROOT"]
      end

      def self.repo_get(nwo, name)
        name ||= nwo[/[^\/]*\/?(\w*)/] && $1
        uri = @gitroot + '/' + nwo

        [name, uri]
      end

      def self.find_or_create_hook(hook_url, repo_url)
        # is there a way to do this? For now, we can just setup
        # the post-receive hook manually.
      end
    end
  end
end