module Janky
  module Git
    module GitHub
      class Mock
        Response = Struct.new(:code, :body)

        def initialize(user, password)
          @repos = {}
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

        def create(nwo, secret, url)
          data = {"url" => "https://api.github.com/hooks/#{Time.now.to_f}"}
          Response.new("201", Yajl.dump(data))
        end

        def get_hook(hook_url)
          Response.new("200")
        end

        def repo_get(nwo)
          return nil if @repos[nwo] == :unauthorized

          {
            "name"    => nwo.split("/").last,
            "private" => (@repos[nwo] == :private),
            "git_url" => "git://github.com/#{nwo}",
            "ssh_url" => "git@github.com:#{nwo}"
          }
        end
      end
    end
  end
end