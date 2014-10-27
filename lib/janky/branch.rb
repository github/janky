module Janky
  class Branch < ActiveRecord::Base
    belongs_to :repository
    has_many :builds, :dependent => :destroy

    # Is this branch green?
    #
    # Returns a Boolean.
    def green?
      if current_build
        current_build.green?
      end
    end

    # Is this branch red?
    #
    # Returns a Boolean.
    def red?
      if current_build
        current_build.red?
      end
    end

    # Is this branch building?
    #
    # Returns a Boolean.
    def building?
      if current_build
        current_build.building?
      end
    end

    # Is this branch completed?
    #
    # Returns a Boolean.
    def completed?
      if current_build
        current_build.completed?
      end
    end

    # Find all completed builds, sorted by completion date, most recent first.
    #
    # Returns an Array of Builds.
    def completed_builds
      builds.completed
    end

    # See Build.queued.
    def queued_builds
      builds.queued
    end

    # Create a build for the given commit.
    #
    # commit  - the Janky::Commit instance to build.
    # user    - The login of the GitHub user who pushed.
    # compare - optional String GitHub Compare View URL. Defaults to the
    #           commit last build, if any.
    # room_id - optional String room ID. Defaults to the room set on
    #           the repository.
    #
    # Returns the newly created Janky::Build.
    def build_for(commit, user, room_id = nil, compare = nil)
      if compare.nil? && build = commit.last_build
        compare = build.compare
      end

      room_id = room_id.to_s
      if room_id.empty? || room_id == "0"
        room_id = repository.room_id
      end

      builds.create!(
        :compare => compare,
        :user    => user,
        :commit  => commit,
        :room_id => room_id
      )
    end

    # Fetch the HEAD commit of this branch using the GitHub API and create a
    # build and commit record.
    #
    # room_id - See build_for documentation. This is passed as is to the
    #           build_for method.
    # user    - Ditto.
    #
    # Returns the newly created Janky::Build.
    def head_build_for(room_id, user)
      sha_to_build = GitHub.branch_head_sha(repository.nwo, name)
      return if !sha_to_build

      commit = repository.commit_for_sha(sha_to_build)

      current_sha = current_build ? current_build.sha1 : "#{sha_to_build}^"
      compare_url = repository.github_url("compare/#{current_sha}...#{commit.sha1}")
      build_for(commit, user, room_id, compare_url)
    end

    # The current build, e.g. the most recent one.
    #
    # Returns a Build.
    def current_build
      builds.last
    end

    # Human readable status of this branch
    #
    # Returns a String.
    def status
      if current_build && current_build.building?
        "building"
      elsif build = completed_builds.first
        if build.green?
          "green"
        elsif build.red?
          "red"
        end
      elsif completed_builds.empty? || builds.empty?
        "no build"
      else
        raise Error, "unexpected branch status: #{id.inspect}"
      end
    end

    # Hash representation of this branch status.
    #
    # Returns a Hash with the name, status, sha1 and compare url.
    def to_hash
      {
        :name    => repository.name,
        :status  => status,
        :sha1    => (current_build && current_build.sha1),
        :compare => (current_build && current_build.compare)
      }
    end
  end
end
