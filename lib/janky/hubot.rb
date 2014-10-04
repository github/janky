module Janky
  # Web API taylored for Hubot's needs. Supports setting up and disabling
  # repositories, querying the status of branch or a repository and triggering
  # builds.
  #
  # The client side implementation is at
  # <https://github.com/github/hubot-scripts/blob/master/src/scripts/janky.coffee>
  class Hubot < Sinatra::Base
    register Helpers

    # Setup a new repository.
    post "/setup" do
      nwo  = params["nwo"]
      name = params["name"]
      tmpl = params["template"]
      repo = Repository.setup(nwo, name, tmpl)

      if repo
        url  = "#{settings.base_url}#{repo.name}"
        [201, "Setup #{repo.name} at #{repo.uri} with #{repo.job_config_path.basename} | #{url}"]
      else
        [400, "Couldn't access #{nwo}. Check the permissions."]
      end
    end

    # Activate/deactivate auto-build for the given repository.
    post "/toggle/:repo_name" do |repo_name|
      repo   = find_repo(repo_name)
      status = repo.toggle_auto_build ? "enabled" : "disabled"

      [200, "#{repo.name} is now #{status}"]
    end

    # Build a repository's branch.
    post %r{\/([-_\.0-9a-zA-Z]+)\/([-_\.a-zA-z0-9\/]+)} do |repo_name, branch_name|
      repo    = find_repo(repo_name)
      branch  = repo.branch_for(branch_name)
      room_id = (params["room_id"] rescue nil)
      user    = params["user"]
      build   = branch.head_build_for(room_id, user)
      build ||= repo.build_sha(branch_name, user, room_id)

      if build
        build.run
        [201, "Going ham on #{build.repo_name}/#{build.branch_name}"]
      else
        [404, "Unknown branch #{branch_name.inspect}. Push again"]
      end
    end

    # Get a list of available rooms.
    get "/rooms" do
      Yajl.dump(ChatService.room_names)
    end

    # Update a repository's notification room.
    put "/:repo_name" do |repo_name|
      repo = find_repo(repo_name)
      room = params["room"]

      if room_id = ChatService.room_id(room)
        repo.update_attributes!(:room_id => room_id)
        [200, "Room for #{repo.name} updated to #{room}"]
      else
        [403, "Unknown room: #{room.inspect}"]
      end
    end

    # Update a repository's context
    put %r{\/([-_\.0-9a-zA-Z]+)\/context} do |repo_name|
      context = params["context"]
      repo = find_repo(repo_name)

      if repo
        repo.context = context
        repo.save
        [200, "Context #{context} set for #{repo_name}"]
      else
        [404, "Unknown Repository #{repo_name}"]
      end
    end

    # Get the status of all projects.
    get "/" do
      content_type "text/plain"
      repos = Repository.all(:include => [:branches, :commits, :builds]).map do |repo|
        master = repo.branch_for("master")

        "%-17s %-13s %-10s %40s" % [
          repo.name,
          master.status,
          repo.campfire_room,
          repo.uri
        ]
      end
      repos.join("\n")
    end

    # Get the lasts builds
    get "/builds" do
      limit = params["limit"]
      building = params["building"]

      builds = Build.unscoped
      if building.blank? || building == 'false'
        builds = builds.completed
      else
        builds = builds.building
      end
      builds = builds.limit(limit) unless limit.blank?

      builds.map! do |build|
        build_to_hash(build)
      end

      builds.to_json
    end

    # Get information about how a project is configured
    get %r{\/show\/([-_\.0-9a-zA-Z]+)} do |repo_name|
      repo   = find_repo(repo_name)
      res = {
        :name => repo.name,
        :configured_job_template => repo.job_template,
        :used_job_template => repo.job_config_path.basename.to_s,
        :repo => repo.uri,
        :room_id => repo.room_id,
        :enabled => repo.enabled,
        :hook_url => repo.hook_url,
        :context => repo.context
      }
      res.to_json
    end

    delete %r{\/([-_\.0-9a-zA-Z]+)} do |repo_name|
      repo   = find_repo(repo_name)
      repo.destroy
      "Janky project #{repo_name} deleted"
    end

    # Delete a repository's context
    delete %r{\/([-_\.0-9a-zA-Z]+)\/context} do |repo_name|
      repo = find_repo(repo_name)

      if repo
        repo.context = nil
        repo.save
        [200, "Context removed for #{repo_name}"]
      else
        [404, "Unknown Repository #{repo_name}"]
      end
    end

    # Get the status of a repository's branch.
    get %r{\/([-_\.0-9a-zA-Z]+)\/([-_\+\.a-zA-z0-9\/]+)} do |repo_name, branch_name|
      limit = params["limit"]

      repo   = find_repo(repo_name)
      branch = repo.branch_for(branch_name)
      builds = branch.queued_builds.limit(limit).map do |build|
        build_to_hash(build)
      end

      builds.to_json
    end

    # Learn everything you need to know about Janky.
    get "/help" do
      content_type "text/plain"
<<-EOS
ci build janky
ci build janky/fix-everything
ci setup github/janky [name]
ci setup github/janky name template
ci toggle janky
ci rooms
ci set room janky development
ci set context janky ci/janky
ci unset context janky
ci status
ci status janky
ci status janky/master
ci builds limit [building]
ci show janky
ci delete janky
EOS
    end

    get "/boomtown" do
      fail "BOOM (janky)"
    end

    private

    def build_to_hash(build)
      { :sha1     => build.sha1,
        :repo     => build.repo_name,
        :branch   => build.branch_name,
        :user     => build.user,
        :green    => build.green?,
        :building => build.building?,
        :queued   => build.queued?,
        :pending  => build.pending?,
        :number   => build.number,
        :status   => (build.green? ? "was successful" : "failed"),
        :compare  => build.compare,
        :duration => build.duration,
        :web_url  => build.web_url }
    end
  end
end
