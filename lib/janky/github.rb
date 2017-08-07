module Janky
  module GitHub
    # Setup the GitHub API client and Post-Receive hook endpoint.
    #
    # user     - API user as a String.
    # password - API password as a String.
    # secret   - Secret used to sign hook requests from GitHub.
    # hook_url - String URL that handles Post-Receive requests.
    # api_url  - GitHub API URL as a String. Requires a trailing slash.
    # git_host - Hostname where git repos are hosted. e.g. "github.com"
    #
    # Returns nothing.
    def self.setup(user, password, secret, hook_url, api_url, git_host)
      @user = user
      @password = password
      @secret = secret
      @hook_url = hook_url
      @api_url = api_url
      @git_host = git_host
    end

    class << self
      attr_reader :secret, :git_host
    end

    # URL of the GitHub website.
    #
    # Retuns the URL as a String. Example: https://github.com
    def self.github_url
      api_uri = URI.parse(@api_url)
      "#{api_uri.scheme}://#{@git_host}"
    end

    # Rack app that handles Post-Receive hook requests from GitHub.
    #
    # Returns a GitHub::Receiver.
    def self.receiver
      @receiver ||= Receiver.new(@secret)
    end

    # Fetch repository details.
    # http://developer.github.com/v3/repos/#get
    #
    # nwo - qualified "owner/repo" name.
    #
    # Returns the Hash representation of the repo, nil when it doesn't exists
    #   or access was denied.
    # Raises an Error for any unexpected response.
    def self.repo_get(nwo)
      response = api.repo_get(nwo)

      case response.code
      when "200"
        Yajl.load(response.body)
      when "403", "404"
        nil
      else
        Exception.push_http_response(response)
        raise Error, "Failed to get hook"
      end
    end

    # Fetch the SHA1 of the given branch HEAD.
    #
    # nwo    - qualified "owner/repo" name.
    # branch - Name of the branch as a String.
    #
    # Returns the SHA1 as a String or nil when the branch doesn't exists.
    def self.branch_head_sha(nwo, branch)
      response = api.branch(nwo, branch)

      branch = Yajl.load(response.body)
      branch && branch["sha"]
    end

    # Fetch commit details for the given SHA1.
    #
    # nwo - qualified "owner/repo" name.
    # sha - SHA1 of the commit as a String.
    #
    # Example
    #
    #   commit("github/janky", "35fff49dc18376845dd37e785c1ea88c6133f928")
    #   => { "commit" => {
    #          "author" => {
    #            "name"  => "Simon Rozet",
    #            "email" => "sr@github.com",
    #          },
    #          "message" => "document and clean up Branch#build_for_head",
    #        }
    #      }
    #
    # Returns the commit Hash.
    def self.commit(nwo, sha)
      response = api.commit(nwo, sha)

      if response.code != "200"
        Exception.push_http_response(response)
        raise Error, "Failed to get commit"
      end

      Yajl.load(response.body)
    end

    # Create a Post-Receive hook for the given repository.
    # http://developer.github.com/v3/repos/hooks/#create-a-hook
    #
    # nwo - qualified "owner/repo" name.
    #
    # Returns the newly created hook URL as String when successful.
    # Raises an Error for any other response.
    def self.hook_create(nwo)
      response = api.create(nwo, @secret, @hook_url)

      if response.code == "201"
        Yajl.load(response.body)["url"]
      else
        Exception.push_http_response(response)
        raise Error, "Failed to create hook"
      end
    end

    # Check existance of a hook.
    # http://developer.github.com/v3/repos/hooks/#get-single-hook
    #
    # url - Hook URL as a String.
    def self.hook_exists?(url)
      api.get(url).code == "200"
    end

    # Delete a post-receive hook for the given repository.
    #
    # hook_url - The repository's hook_url
    #
    # Returns true or raises an exception.
    def self.hook_delete(url)
      response = api.delete(url)

      if response.code == "204"
        true
      else
        Exception.push_http_response(response)
        raise Error, "Failed to delete hook"
      end
    end

    # Default API implementation that goes over the wire (HTTP).
    #
    # Returns nothing.
    def self.api
      @api ||= API.new(@api_url, @user, @password)
    end

    # Turn on mock mode, meaning no request goes over the wire. Useful in
    # testing environments.
    #
    # Returns nothing.
    def self.enable_mock!
      @api = Mock.new(@user, @password)
    end

    # Make any subsequent response for the given repository look like as if
    # it was a private repo.
    #
    # nwo - qualified "owner/repo" name.
    #
    # Returns nothing.
    def self.repo_make_private(nwo)
      api.make_private(nwo)
    end

    # Make any subsequent request to the given repository succeed. Only
    # available in mock mode.
    #
    # nwo - qualified "owner/repo" name.
    #
    # Returns nothing.
    def self.repo_make_public(nwo)
      api.make_public(nwo)
    end

    # Make any subsequent request for the given repository fail with an
    # unauthorized response. Only available when mocked.
    #
    # nwo - qualified "owner/repo" name.
    #
    # Returns nothing.
    def self.repo_make_unauthorized(nwo)
      api.make_unauthorized(nwo)
    end

    # Set the SHA of the named branch for the given repo. Mock only.
    def self.set_branch_head(nwo, branch, sha)
      api.set_branch_head(nwo, branch, sha)
    end
  end
end
