module Janky
  class Repository < ActiveRecord::Base
    has_many :branches, :dependent => :destroy
    has_many :commits, :dependent => :destroy
    has_many :builds, :through => :branches

    after_commit :delete_hook, :on => :destroy

    replicate_associations :builds, :commits, :branches

    default_scope(order("name"))

    def self.setup(nwo, name = nil, template = nil)
      if nwo.nil?
        raise ArgumentError, "nwo can't be nil"
      end

      if repo = Repository.find_by_name(nwo)
        repo.update_attributes!(:job_template => template)
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
          repo.update_attributes!(:uri => uri, :job_template => template)
          repo
        else
          Repository.create!(:name => name, :uri => uri, :job_template => template)
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
      branches.find_or_create_by_name(name)
    end

    # Create or retrieve the given commit.
    #
    # commit - The Hash representation of the Commit.
    #
    # Returns a Commit record.
    def commit_for(commit)
      commits.find_by_sha1(commit[:sha1]) ||
        commits.create!(commit)
    end

    def commit_for_sha(sha1)
      commit_data = GitHub.commit(nwo, sha1)
      commit_message = commit_data["commit"]["message"]
      commit_url = github_url("commit/#{sha1}")
      author_data = commit_data["commit"]["author"]
      commit_author =
        if email = author_data["email"]
          "#{author_data["name"]} <#{email}>"
        else
          author_data["name"]
        end

      commit = commit_for({
        :repository => self,
        :sha1 => sha1,
        :author => commit_author,
        :message => commit_message,
        :url => commit_url,
      })
    end

    # Create a Janky::Build object given a sha
    #
    # sha1    - a string of the target sha to build
    # user    - The login of the GitHub user who pushed.
    # room_id - optional Fixnum Campfire room ID. Defaults to the room set on
    # compare - optional String GitHub Compare View URL. Defaults to the
    #
    # Returns the newly created Janky::Build
    def build_sha(sha1, user, room_id = nil, compare = nil)
      return nil unless sha1 =~ /^[0-9a-fA-F]{7,40}$/
      commit = commit_for_sha(sha1)
      commit.build!(user, room_id, compare)
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
      delete_hook

      url = GitHub.hook_create("#{github_owner}/#{github_name}")
      update_attributes!(:hook_url => url)
    end

    def delete_hook
      if self.hook_url? && GitHub.hook_exists?(self.hook_url)
        GitHub.hook_delete(self.hook_url)
      end
    end

    # Creates a job on the Jenkins server for this repository configuration
    # unless one already exists. Can safely be run multiple times.
    #
    # Returns nothing.
    def setup_job
      builder.setup(job_name, uri, job_config_path)
    end

    # The path of the Jenkins configuration template. Try
    # "<job_template>.xml.erb" first, "<repo-name>.xml.erb" second, and then
    # fallback to "default.xml.erb" under the root config directory.
    #
    # Returns the template path as a Pathname.
    def job_config_path
      user_override = Janky.jobs_config_dir.join("#{job_template.downcase}.xml.erb") if job_template
      custom = Janky.jobs_config_dir.join("#{name.downcase}.xml.erb")
      default = Janky.jobs_config_dir.join("default.xml.erb")

      if user_override && user_override.readable?
        user_override
      elsif custom.readable?
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
