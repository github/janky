require File.expand_path("../lib/janky/version", __FILE__)

Gem::Specification.new "janky", Janky::VERSION do |s|
  s.description = "Janky is a Continuous Integration server"
  s.summary = "Continuous Integration server built on top of Jenkins and " \
    "designed for GitHub and Hubot"
  s.authors = ["Simon Rozet"]
  s.homepage = "https://github.com/github/janky"
  s.has_rdoc = false
  s.license  = "MIT"

  s.post_install_message = <<-EOL
If you are upgrading from Janky 0.9.13, you will want to add a JANKY_BRANCH parameter
to your config/default.xml.erb. See
https://github.com/github/janky/commit/0fc6214e3a75cc138aed46a2493980440e848aa3#commitcomment-1815400 for details.
EOL

  # runtime
  s.add_dependency "rake", "~>0.9.2"
  s.add_dependency "sinatra", "~>1.3"
  s.add_dependency "sinatra_auth_github", "~>1.0.0"
  s.add_dependency "mustache", "~>0.11"
  s.add_dependency "yajl-ruby", "~>1.1.0"
  s.add_dependency "activerecord", "~>3.2.0"
  s.add_dependency "broach", "~>0.2"
  s.add_dependency "replicate", "~>1.4"

  # development
  s.add_development_dependency "shotgun", "~>0.9"
  s.add_development_dependency "thin", "~>1.2"
  s.add_development_dependency "mysql2", "~>0.3.0"

  # test
  s.add_development_dependency "database_cleaner", "~>0.6"
  s.add_development_dependency "mocha", "~>0.10.4"

  s.files = %w[
CHANGES
COPYING
Gemfile
README.md
Rakefile
config.ru
janky.gemspec
lib/janky.rb
lib/janky/app.rb
lib/janky/branch.rb
lib/janky/build.rb
lib/janky/build_request.rb
lib/janky/builder.rb
lib/janky/builder/client.rb
lib/janky/builder/http.rb
lib/janky/builder/mock.rb
lib/janky/builder/payload.rb
lib/janky/builder/receiver.rb
lib/janky/builder/runner.rb
lib/janky/chat_service.rb
lib/janky/chat_service/campfire.rb
lib/janky/chat_service/hipchat.rb
lib/janky/chat_service/mock.rb
lib/janky/commit.rb
lib/janky/database/migrate/1312115512_init.rb
lib/janky/database/migrate/1312117285_non_unique_repo_uri.rb
lib/janky/database/migrate/1312198807_repo_enabled.rb
lib/janky/database/migrate/1313867551_add_build_output_column.rb
lib/janky/database/migrate/1313871652_add_commit_url_column.rb
lib/janky/database/migrate/1317384618_add_repo_hook_url.rb
lib/janky/database/migrate/1317384619_add_build_room_id.rb
lib/janky/database/migrate/1317384629_drop_default_room_id.rb
lib/janky/database/migrate/1317384649_github_team_id.rb
lib/janky/database/migrate/1317384650_add_build_indexes.rb
lib/janky/database/migrate/1317384651_add_more_build_indexes.rb
lib/janky/database/migrate/1317384652_change_commit_message_to_text.rb
lib/janky/database/migrate/1317384653_add_build_pusher.rb
lib/janky/database/migrate/1317384654_add_build_queued_at.rb
lib/janky/database/schema.rb
lib/janky/database/seed.dump.gz
lib/janky/exception.rb
lib/janky/github.rb
lib/janky/github/api.rb
lib/janky/github/commit.rb
lib/janky/github/mock.rb
lib/janky/github/payload.rb
lib/janky/github/payload_parser.rb
lib/janky/github/receiver.rb
lib/janky/helpers.rb
lib/janky/hubot.rb
lib/janky/job_creator.rb
lib/janky/notifier.rb
lib/janky/notifier/chat_service.rb
lib/janky/notifier/github_status.rb
lib/janky/notifier/mock.rb
lib/janky/notifier/multi.rb
lib/janky/public/css/base.css
lib/janky/public/images/building-bot.gif
lib/janky/public/images/disclosure-arrow.png
lib/janky/public/images/logo.png
lib/janky/public/images/robawt-status.gif
lib/janky/public/javascripts/application.js
lib/janky/public/javascripts/jquery.js
lib/janky/public/javascripts/jquery.relatize.js
lib/janky/repository.rb
lib/janky/tasks.rb
lib/janky/templates/console.mustache
lib/janky/templates/index.mustache
lib/janky/templates/layout.mustache
lib/janky/version.rb
lib/janky/views/console.rb
lib/janky/views/index.rb
lib/janky/views/layout.rb
]

s.test_files = %w[
test/default.xml.erb
test/janky_test.rb
test/test_helper.rb
]
end
