module Janky
  module GitHub
    class Mock
      Response = Struct.new(:code, :body)

      def initialize(user, password)
        @repos = {}
        @branch_shas = {}
      end

      def make_private(nwo)
        @repos[nwo] = :private
      end

      def make_public(nwo)
        @repos[nwo] = :public
      end

      def make_unauthorized(nwo)
        @repos[nwo] = :unauthorized
      end

      def set_branch_head(nwo, branch, sha)
        @branch_shas[[nwo, branch]] = sha
      end

      def create(nwo, secret, url)
        data = {"url" => "https://api.github.com/hooks/#{Time.now.to_f}"}
        Response.new("201", Yajl.dump(data))
      end

      def get(url)
        Response.new("200")
      end

      def delete(url)
        Response.new("204")
      end

      def repo_get(nwo)
        repo = {
          "name"    => nwo.split("/").last,
          "private" => (@repos[nwo] == :private),
          "git_url" => "git://github.com/#{nwo}",
          "ssh_url" => "git@github.com:#{nwo}"
        }

        if @repos[nwo] == :unauthorized
          Response.new("404", Yajl.dump({}))
        else
          Response.new("200", Yajl.dump(repo))
        end
      end

      def branch(nwo, branch)

        data = { "sha" => @branch_shas[[nwo, branch]] }

        Response.new("200", Yajl.dump(data))
      end

      def commit(nwo, sha)
        data = {
          "commit" => {
            "author" => {
              "name"  => "Test Author",
              "email" => "test@github.com"
            },
            "message" => "Test Message"
          }
        }

        Response.new("200", Yajl.dump(data))
      end
    end
  end
end
