module Janky
  class Repository < ActiveRecord::Base
    has_many :branches, :dependent => :destroy
    has_many :commits, :dependent => :destroy
    has_many :builds, :through => :branches

    replicate_associations :builds, :commits, :branches

    default_scope { order("name") }

    def self.setup(nwo, name = nil)
      if nwo.nil?
        raise ArgumentError, "nwo can't be nil"
      end

      if repo = Repository.find_by_name(nwo)
        repo.setup
        return repo
      end

      repo = GitHub.repo_get(nwo)
      return if !repo

      uri    = repo["private"] ? repo["ssh_url"] : repo["git_url"]
      name ||= repo["name"]
      uri.gsub!(/\.git$/, "")

      repo =
        if repo = Repository.find_by_name(name)
          repo.update_attributes!(:uri => uri)
          repo
        else
          Repository.create!(:name => name, :uri => uri)
        end

      repo.setup
      repo
    end

    # Find a named repository.
    #
    # name - The String name of the repository.
    #
    # Returns a Repository or nil when it doesn't exists.
    def self.by_name(name)
      find_by_name(name)
    end

    # Toggle auto-build feature of this repo. When enabled (default),
    # all branches are built automatically.
    #
    # Returns the new flag status as a Boolean.
    def toggle_auto_build
      toggle(:enabled)
      save!
      enabled
    end

    # Create or retrieve the named branch.
    #
    # name - The branch's name as a String.
    #
    # Returns a Branch record.
    def branch_for(name)
      branches.find_or_create_by(name: name)
    end

    # Create or retrieve the given commit.
    #
    # name - The Hash representation of the Commit.
    #
    # Returns a Commit record.
    def commit_for(commit)
      commits.find_by_sha1(commit[:sha1]) ||
        commits.create(commit)
    end

    # Jenkins host executing this repo's builds.
    #
    # Returns a Builder::Client.
    def builder
      Builder.pick_for(self)
    end

    # GitHub user owning this repo.
    #
    # Returns the user name as a String.
    def github_owner
      uri[/.*[\/:]([a-zA-Z0-9\-_]+)\//] && $1
    end

    # Name of this repository on GitHub.
    #
    # Returns the name as a String.
    def github_name
      uri[/.*[\/:]([a-zA-Z0-9\-_]+)\/([a-zA-Z0-9\-_\.]+)/] && $2
    end

    # Fully qualified GitHub name for this repository.
    #
    # Returns the name as a String. Example: github/janky.
    def nwo
      "#{github_owner}/#{github_name}"
    end

    # Append the given path to the GitHub URL of this repository.
    #
    # path - String path. No slash necessary at the front.
    #
    # Examples
    #
    #   github_url("issues")
    #   => "https://github.com/github/janky/issues"
    #
    # Returns the URL as a String.
    def github_url(path)
      "#{GitHub.github_url}/#{nwo}/#{path}"
    end

    # Name of the Campfire room receiving build notifications.
    #
    # Returns the name as a String.
    def campfire_room
      ChatService.room_name(room_id)
    end

    # Ditto but returns the Fixnum room id. Defaults to the one set
    # in Campfire.setup.
    def room_id
      read_attribute(:room_id) || ChatService.default_room_id
    end

    # Setups GitHub and Jenkins for building this repository.
    #
    # Returns nothing.
    def setup
      setup_job
      setup_hook
    end

    # Create a GitHub hook for this Repository and store its URL if needed.
    #
    # Returns nothing.
    def setup_hook
      if !hook_url || !GitHub.hook_exists?(hook_url)
        url = GitHub.hook_create("#{github_owner}/#{github_name}")
        update_attributes!(:hook_url => url)
      end
    end

    # Creates a job on the Jenkins server for this repository configuration
    # unless one already exists. Can safely be run multiple times.
    #
    # Returns nothing.
    def setup_job
      builder.setup(job_name, uri, job_config_path)
    end

    # The path of the Jenkins configuration template. Try "<repo-name>.xml.erb"
    # first then fallback to "default.xml.erb" under the root config directory.
    #
    # Returns the template path as a Pathname.
    def job_config_path
      custom = Janky.jobs_config_dir.join("#{name.downcase}.xml.erb")
      default = Janky.jobs_config_dir.join("default.xml.erb")

      if custom.readable?
        custom
      elsif default.readable?
        default
      else
        raise Error, "no config.xml.erb template for repo #{id.inspect}"
      end
    end

    # Construct the URL pointing to this Repository's Jenkins job.
    #
    # Returns the String URL.
    def job_url
      builder.url + "job/#{job_name}"
    end

    # Calculate the name of the Jenkins job.
    #
    # Returns a String hash of this Repository name and uri.
    def job_name
      md5 = Digest::MD5.new
      md5 << name
      md5 << uri
      md5 << job_config_path.read
      md5 << builder.callback_url.to_s
      "#{name}-#{md5.hexdigest[0,12]}"
    end
  end
end
