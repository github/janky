module Janky
  class Branch < ActiveRecord::Base
    belongs_to :repository
    has_many :builds

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

    # Create a build for the given commit.
    #
    # commit  - the Janky::Commit instance to build.
    # compare - optional String GitHub Compare View URL. Defaults to the
    #           commit last build, if any.
    # room_id - optional Fixnum Campfire room ID. Defaults to the room set on
    #           the repository.
    #
    # Returns the newly created Janky::Build.
    def build_for(commit, room_id = nil, compare = nil)
      if compare.nil? && build = commit.last_build
        compare = build.compare
      end

      if room_id.nil? || room_id.zero?
        room_id = repository.room_id
      end

      builds.create(
        :compare => compare,
        :commit  => commit,
        :room_id => room_id
      )
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
