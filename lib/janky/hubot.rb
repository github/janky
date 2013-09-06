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
      repo = Repository.setup(nwo, name)

      if repo
        url  = "#{settings.base_url}#{repo.name}"
        [201, "Setup #{repo.name} at #{repo.uri} | #{url}"]
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
      room_id = (params["room_id"] && Integer(params["room_id"]) rescue nil)
      user    = params["user"]
      build   = branch.head_build_for(room_id, user)

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

    # Get the status of all projects.
    get "/" do
      content_type "text/plain"
      repos = Repository.includes([:branches, :commits, :builds]).to_a.map do |repo|
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

    # Get the status of a repository's branch.
    get %r{\/([-_\.0-9a-zA-Z]+)\/([-_\+\.a-zA-z0-9\/]+)} do |repo_name, branch_name|
      limit = params["limit"]

      repo   = find_repo(repo_name)
      branch = repo.branch_for(branch_name)
      builds = branch.queued_builds.limit(limit).map do |build|
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
          :duration => build.duration }
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
ci toggle janky
ci rooms
ci set room janky development
ci status
ci status janky
ci status janky/master
EOS
    end

    get "/boomtown" do
      fail "BOOM (janky)"
    end
  end
end
