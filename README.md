Janky
=====

This is Janky, a continuous integration server built on top of
[Jenkins][], controlled by [Hubot][], and designed for [GitHub][].

* **Built on top of Jenkins.** The power, vast amount of plugins and large
  community of the popular CI server all wrapped up in a great experience.

* **Controlled by Hubot.** Day to day operations are exposed as simple
  Hubot commands that the whole team can use.

* **Designed for GitHub.** Janky creates the appropriate [web hooks][w] for
  you and the web app restricts access to members of your GitHub organization.

[GitHub]: https://github.com
[Hubot]: http://hubot.github.com
[Jenkins]: http://jenkins-ci.org
[w]: http://developer.github.com/v3/repos/hooks/

Hubot usage
-----------

Start by setting up a new Jenkins job and GitHub web hook for a
repository:

    hubot ci setup github/janky

The `setup` command can safely be run over and over again. It won't do
anything unless it needs to. It takes an optional name argument:

    hubot ci setup github/janky janky-ruby1.9.2

It also takes an optional template name argument:

    hubot ci setup github/janky janky-ruby1.9.2 ruby-build

All branches are built automatically on push. Disable auto build with:

    hubot ci toggle janky

Run the command again to re-enable it. Force a build of the master
branch:

    hubot ci build janky

Of a specific branch:

    hubot ci build janky/libgit2

Different builds aren't relevant to the same Campfire room and so Janky
lets you choose where notifications are sent to. First get a list of
available rooms:

    hubot ci rooms

Then pick one:

    hubot ci set room janky The Serious Room

Get the status of a build:

    hubot ci status janky

Specific branch:

    hubot ci status janky/libgit2

All builds:

    hubot ci status

Finally, get a quick reference of the available commands with:

    hubot ci?

Installing
----------

### Jenkins

Janky requires access to a Jenkins server. Version **1.427** is
recommended. Refer to the Jenkins [documentation][doc] for installation
instructions and install the [Notification Plugin][np] version 1.4.

Remember to set the Jenkins URL in `http://your-jenkins-server.com/configure`.
Janky will still trigger builds but will not update the build status without this set.

[doc]: https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins
[np]: https://wiki.jenkins-ci.org/display/JENKINS/Notification+Plugin

### Deploying

Janky is designed to be deployed to [Heroku](https://heroku.com).

Grab all the necessary files from [the gist][gist]:

    $ git clone git://gist.github.com/1497335 janky

Then push it up to a new Heroku app:

    $ cd janky
    $ heroku create --stack cedar
    $ bundle install
    $ git add Gemfile.lock
    $ git commit Gemfile.lock -m "lock bundle"
    $ git push heroku master

After configuring the app (see below), create the database:

    $ heroku run rake db:migrate

**NOTE:** Ruby version 2.0.0+ is required to run Janky.

[gist]: https://gist.github.com/1497335

Upgrading
---------

We **strongly recommend** backing up your Janky database before upgrading.

The general process is to then upgrade the gem, and then run migrate.  Here is how
you do that on a local box you have access to (this process will differ for Heroku):

    cd [PATH-TO-JANKY]
    gem update janky
    rake db:migrate

Configuring
-----------

Janky is configured using environment variables. Use the `heroku config`
command:

    $ heroku config:add VARIABLE=value

Required settings:

* `JANKY_BASE_URL`: The application URL **with** a trailing slash. Example:
  `http://mf-doom-42.herokuapp.com/`.
* `JANKY_BUILDER_DEFAULT`: The Jenkins server URL **with** a trailing slash.
   Example: `http://jenkins.example.com/`. For basic auth, include the
   credentials in the URL: `http://user:pass@jenkins.example.com/`.
   Using GitHub OAuth with Jenkins is not supported by Janky.
* `JANKY_CONFIG_DIR`: Directory where build config templates are stored.
  Typically set to `/app/config` on Heroku.
* `JANKY_HUBOT_USER`: Login used to protect the Hubot API.
* `JANKY_HUBOT_PASSWORD`: Password for the Hubot API.
* `JANKY_GITHUB_USER`: The login of the GitHub user used to access the
  API. Requires Administrative privileges to set up service hooks.
* `JANKY_GITHUB_PASSWORD`: The password for the GitHub user.
* `JANKY_GITHUB_HOOK_SECRET`: Secret used to sign hook requests from
  GitHub.
* `JANKY_CHAT_DEFAULT_ROOM`: Chat room where notifications are sent by default.

Optional database settings:

* `DATABASE_URL`: Database connection URL. Example:
  `postgres://user:password@host:port/db_name`.
* `JANKY_DATABASE_SOCKET`: Path to the database socket. Example:
  `/var/run/mysql5/mysqld.sock`.

### GitHub Enterprise

Using Janky with [GitHub Enterprise][ghe] requires one extra setting:

* `JANKY_GITHUB_API_URL`: Full API URL of the instance, *with* a trailing
  slash. Example: `https://github.example.com/api/v3/`.

[ghe]: https://enterprise.github.com

### GitHub Status API

https://github.com/blog/1227-commit-status-api

To update pull requests with the build status generate an OAuth token
via the GitHub API:

    curl -u username:password \
      -d '{ "scopes": [ "repo:status" ], "note": "janky" }' \
      https://api.github.com/authorizations

then set `JANKY_GITHUB_STATUS_TOKEN`.  Optionally, you can also set
`JANKY_GITHUB_STATUS_CONTEXT` to send a context to the GitHub API by
default

`username` and `password` in the above example should be the same as the
values provided for `JANKY_GITHUB_USER` and `JANKY_GITHUB_PASSWORD`
respectively.

### Chat notifications

#### Campfire
Janky notifies [Campfire][] chat rooms by default. Required settings:

* `JANKY_CHAT_CAMPFIRE_ACCOUNT`: account name.
* `JANKY_CHAT_CAMPFIRE_TOKEN`: authentication token for the user sending
  build notifications.

[Campfire]: http://campfirenow.com/

#### HipChat

Required settings:

* `JANKY_CHAT=hipchat`
* `JANKY_CHAT_HIPCHAT_TOKEN`: authentication token (This token needs to be an
  admin token, not a notification token.)
* `JANKY_CHAT_HIPCHAT_FROM`: name that messages will appear be sent from.
  Defaults to `CI`.
* `JANKY_HUBOT_USER` should be XMPP/Jabber username in format xxxxx_xxxxxx
  rather than email
* `JANKY_CHAT_DEFAULT_ROOM` should be the name of the room instead of the
  XMPP format, for example: `Engineers` instead of xxxx_xxxxxx.

Installation:

* Add `require "janky/chat_service/hipchat"` to the `config/environment.rb`
  file **before** the `Janky.setup(ENV)` line.
* `echo 'gem "hipchat", "~>0.4"' >> Gemfile`
* `bundle`
* `git commit -am "install hipchat"`

#### Hubot

Sends notifications to Hubot via [janky script](http://git.io/hubot-janky).

Required settings:

* `JANKY_CHAT_HUBOT_URL`: URL to your Hubot instance.
* `JANKY_CHAT_HUBOT_ROOMS`: List of rooms which can be set via `ci set room`.
  * For IRC: Comma-separated list of channels `"#room, #another-room"`
  * For Campfire/HipChat: List with room id and name `"34343:room, 23223:another-room"`

### Authentication

To restrict access to members of a GitHub organization, [register a new
OAuth application on GitHub](https://github.com/settings/applications)
with the callback set to `$JANKY_BASE_URL/auth/github/callback` then set
a few extra settings:

* `JANKY_SESSION_SECRET`: Random session cookie secret. Typically
  generated by a tool like `pwgen`.
* `JANKY_AUTH_CLIENT_ID`: The client ID of the OAuth application.
* `JANKY_AUTH_CLIENT_SECRET`: The client secret of the OAuth application.
* `JANKY_AUTH_ORGANIZATION`: The organization name. Example: "github".
* `JANKY_AUTH_TEAM_ID`: An optional team ID to give auth to. Example: "1234".

### Hubot

Install the [janky script](http://git.io/hubot-janky) in your Hubot
then set the `HUBOT_JANKY_URL` environment variable. Example:
`http://user:password@janky.example.com/_hubot/`, with user and password
replaced by `JANKY_HUBOT_USER` and `JANKY_HUBOT_PASSWORD` respectively.

### Custom build configuration

The default build command should suffice for most Ruby applications:

    $ bundle install --path vendor/gems --binstubs
    $ bundle exec rake

For more control you can add a `script/cibuild` at the root of your
repository for Jenkins to execute instead.

For total control, whole Jenkins' `config.xml` files can be associated
with Janky builds. Given a build called `windows` and a template name
of `psake`, Janky will try `config/jobs/psake.xml.erb` to use a template,
`config/jobs/windows.xml.erb` to try the job name if the template does
not exit,  before finally falling back to the default
configuration, `config/jobs/default.xml.erb`. After updating or adding
a custom config, run `hubot ci setup` again to update the Jenkins
server.

Hacking
-------

Get your environment up and running:

    script/bootstrap

Create the databases:

    mysqladmin -uroot create janky_development
    mysqladmin -uroot create janky_test

Create the tables:

    RACK_ENV=development bin/rake db:migrate
    RACK_ENV=test bin/rake db:migrate

Seed some data into the development database:

    bin/rake db:seed

Start the server:

    script/server

Open the app:

    open http://localhost:9393/

Run the test suite:

    script/test

Contributing
------------

Fork the [Janky repository on GitHub](https://github.com/github/janky) and
send a Pull Request.  Note that any changes to behavior without tests will
be rejected.  If you are adding significant new features, please add both
tests and documentation.

Copying
-------

Copyright © 2011-2013, GitHub, Inc. See the `COPYING` file for license
rights and limitations (MIT).
