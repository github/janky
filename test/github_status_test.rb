require File.expand_path("../test_helper", __FILE__)

class GithubStatusTest < Test::Unit::TestCase
  def stub_build
    @stub_build = stub(:repo_nwo => "github/janky",
      :sha1 => "xxxx",
      :green? => true,
      :number => 1,
      :duration => 1,
      :repository => stub(:context => "ci/janky"),
      :web_url => "http://example.com/builds/1")
  end

  def setup
    # never allow any outgoing requests
    Net::HTTP.any_instance.stubs(:request)
  end

  test "sending successful status uses the right path" do
    post = stub_everything
    Net::HTTP::Post.expects(:new).with("/repos/github/janky/statuses/xxxx").returns(post)
    notifier = Janky::Notifier::GithubStatus.new("token", "http://example.com/")
    notifier.completed(stub_build)
  end
end
