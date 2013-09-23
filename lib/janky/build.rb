module Janky
  class Build < ActiveRecord::Base
    belongs_to :branch
    belongs_to :commit

    # Use validates_each so that `output_limit` is evaluated when the database
    # connection is up
    validates_each :output do |record, attr, value|
      length = output_limit
      record.errors.add(attr, "output must be less than #{length} characters") unless length.nil? || value.size <= length
    end

    default_scope do
      columns = (column_names - ["output"]).map do |column_name|
        arel_table[column_name]
      end

      select(columns)
    end

    # Transition the Build to the started state.
    #
    # id  - the Fixnum ID used to find the build.
    # url - the full String URL of the build.
    #
    # Returns nothing or raises an Error for inexistant builds.
    def self.start(id, url)
      if build = find_by_id(id)
        build.start(url, Time.now)
      else
        raise Error, "Unknown build: #{id.inspect}"
      end
    end

    # Transition the Build to the completed state.
    #
    # id    - the Fixnum ID used to find the build.
    # green - Boolean indicating build success.
    #
    # Returns nothing or raises an Error for inexistant builds.
    def self.complete(id, green)
      if build = find_by_id(id)
        build.complete(green, Time.now)
      else
        raise Error, "Unknown build: #{id.inspect}"
      end
    end

    # Find all builds that have been queued in Jenkins, most recent first.
    #
    # Returns an Array of Build objects.
    def self.queued
      where("queued_at IS NOT NULL").order("queued_at DESC, id DESC")
    end

    # Find all started builds, most recent first.
    #
    # Returns an Array of Builds.
    def self.started
      where("started_at IS NOT NULL").order("started_at DESC, id DESC")
    end

    # Find all completed builds, most recent first.
    #
    # Returns an Array of Builds.
    def self.completed
      started.
        where("completed_at IS NOT NULL")
    end

    # Find all green builds, most recent first.
    #
    # Returns an Array of Builds.
    def self.green
      completed.where(:green => true)
    end

    # Has this build been queued in Jenkins?
    #
    # Returns true when the build is complete or currently being built,
    #   false otherwise.
    def queued?
      ! queued_at.nil?
    end

    # Is this build currently sitting in the queue waiting to be built?
    #
    # Returns true if the build is queued and not started, false otherwise.
    def pending?
      queued? && !started?
    end

    # Is this build currently being built?
    #
    # Returns a Boolean.
    def building?
      started? && !completed?
    end

    # Is this build red?
    #
    # Returns a Boolean, nothing when the build hasn't completed yet.
    def red?
      completed? && !green?
    end

    # Was this build ever started?
    #
    # Returns a Boolean.
    def started?
      ! started_at.nil?
    end

    # Did this build complete?
    #
    # Returns a Boolean.
    def completed?
      ! completed_at.nil?
    end

    # Trigger a Jenkins build using the appropriate builder.
    #
    # Returns nothing.
    def run
      builder.run(self)
      update_attributes!(:queued_at => Time.now)
    end

    # See Repository#builder.
    def builder
      branch.repository.builder
    end

    # Run a copy of itself. Typically used to force a build in case of
    # temporary test failure or when auto-build is disabled.
    #
    # new_room_id - optional Campfire room Fixnum ID. Defaults to the room of the
    #               build being re-run.
    #
    # Returns the build copy.
    def rerun(new_room_id = nil)
      build = branch.build_for(commit, new_room_id)
      build.run
      build
    end

    # Cached or remote build output.
    #
    # Returns the String output.
    def output
      if completed?
        read_attribute(:output)
      elsif started?
        output_remote
      else
        ""
      end
    end

    # Output is truncatable so that it fits in the database
    #
    # We can hit the column size limit or the MySQL max_allowed_packet limit
    def self.output_limit
      limits = []

      column_limit = columns_hash['output'].limit
      limits << column_limit unless column_limit.nil?

      conn = connection
      max_packet_limit = if conn.is_a? ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
        result = conn.execute("SHOW VARIABLES LIKE 'max_allowed_packet';")

        variables = {}
        result.each do |row|
          variables.merge! Hash[*row]
        end

        # Remove 1KB from the max allowed packet for leeway, ensures large
        # output combined with the other columns doesn't exceed the max allowed
        # packet size
        variables['max_allowed_packet'].to_i - 1024
      else
        nil
      end

      limits << max_packet_limit unless max_packet_limit.nil?

      limits.min
    end

    # Retrieve the build output from the Jenkins server.
    #
    # Returns the String output.
    def output_remote
      if started?
        output = builder.output(self)

        limit = self.class.output_limit
        return output if limit.nil? || output.size < limit

        truncation_warning = "This build's output is too long for Janky, reduce how much is logged so that it can be stored fully\n\n"
        truncation_warning + output.slice((output.size - (limit - truncation_warning.size))..output.size)
      end
    end

    # Mark the build as started.
    #
    # url - the full String URL of the build on the Jenkins server.
    # now - the Time at which the build started.
    #
    # Returns nothing or raise an Error for weird transitions.
    def start(url, now)
      if started?
        raise Error, "Build #{id} already started"
      elsif completed?
        raise Error, "Build #{id} already completed"
      else
        update_attributes!(:url => url, :started_at => now)
        Notifier.started(self)
      end
    end

    # Mark the build as complete, store the build output and notify Campfire.
    #
    # green - Boolean indicating build success.
    # now   - the Time at which the build completed.
    #
    # Returns nothing or raise an Error for weird transitions.
    def complete(green, now)
      if ! started?
        raise Error, "Build #{id} not started"
      elsif completed?
        raise Error, "Build #{id} already completed"
      else
        update_attributes!(
          :green        => green,
          :completed_at => now,
          :output       => output_remote
        )
        Notifier.completed(self)
      end
    end

    # The time it took to peform this build in seconds.
    #
    # Returns an Integer seconds.
    def duration
      if completed?
        Integer(completed_at - started_at)
      end
    end

    # The name of the Campfire room where notifications are sent.
    #
    # Returns the String room name.
    def room_name
      if room_id && room_id > 0
        ChatService.room_name(room_id)
      end
    end

    class << self
      # The full URL of the web app as a String, including the protocol.
      attr_accessor :base_url

      # The full URL to the Jenkins build page, as a String.
      attr_reader :url
    end

    # URL of this build's web page, served by Janky::App.
    #
    # Returns the URL as a String.
    def web_url
      return if new_record?
      self.class.base_url + "#{id}/output"
    end

    # URL of the web page for this build's branch, served by Janky::App.
    #
    # Returns the URL as a String.
    def branch_url
      return if new_record?
      self.class.base_url + "#{repo_name}/#{branch_name}"
    end

    def repo_id
      repository.id
    end

    def repo_job_name
      repository.job_name
    end

    def repo_name
      repository.name
    end

    def repo_nwo
      repository.nwo
    end

    def repository
      branch.repository
    end

    def repo
      branch.repository
    end

    def sha1
      commit.sha1
    end

    def short_sha1
      sha1[0,7]
    end

    def commit_url
      commit.url
    end

    def commit_message
      commit.message
    end

    def commit_author
      commit.author
    end

    def number
      id.to_s
    end

    def branch_name
      branch.name
    end
  end
end
