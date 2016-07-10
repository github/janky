module Janky
  module Helpers
    def self.registered(app)
      app.enable :raise_errors
      app.disable :show_exceptions
      app.helpers self
    end

    def find_repo(name)
      unless repo = Repository.find_by_name(name)
        halt(404, "Unknown repository: #{name.inspect}")
      end

      repo
    end

    def find_queued_builds_for(branch_name)
      branches = Branch.find(:all, :conditions => ["name = ?", branch_name])
      halt(404, "Unknown branch: #{branch_name}") if branches.empty?

      branches.map(&:queued_builds).flatten
    end
  end
end
