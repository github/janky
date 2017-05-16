module Janky
  class App < Sinatra::Base
    register Mustache::Sinatra
    register Helpers

    set    :app_file, __FILE__
    enable :static

    set :mustache, {
      :namespace => Janky,
      :views     => File.join(root, "views"),
      :templates => File.join(root, "templates")
    }

    before do
      if organization = github_organization
        github_organization_authenticate!(organization)
      end
    end

    def github_organization
      settings.respond_to?(:github_organization) && settings.github_organization
    end

    def github_team_id
      settings.respond_to?(:github_team_id) && settings.github_team_id
    end

    def authorize_index
      if github_team_id
        github_team_authenticate!(github_team_id)
      end
    end

    def authorize_repo(repo)
      if team_id = (repo.github_team_id || github_team_id)
        github_team_authenticate!(team_id)
      end
    end

    get "/?" do
      authorize_index
      @builds = Build.queued.first(50)
      mustache :index
    end

    get "/:build_id/output" do |build_id|
      @build = Build.select(:output).find(build_id)
      authorize_repo(@build.repo)
      mustache :console, :layout => false
    end

    get "/:repo_name" do |repo_name|
      repo = find_repo(repo_name)
      authorize_repo(repo)

      @builds = repo.builds.queued.first(50)
      mustache :index
    end

    get %r{^(?!\/auth\/github\/callback)\/([-_\.0-9a-zA-Z]+)\/([-_\.a-zA-z0-9\/]+)} do |repo_name, branch|
      repo = find_repo(repo_name)
      authorize_repo(repo)

      @builds = repo.branch_for(branch).queued_builds.first(50)
      mustache :index
    end
  end
end
