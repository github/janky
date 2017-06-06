# helpers
tap "github/bootstrap"

# ruby
brew "openssl"
brew "autoconf"
brew "rbenv"
brew "ruby-build"

if ENV["BOXEN_HOME"]
  brew "boxen/brews/mysql"
else
  brew "homebrew/versions/mysql56", restart_service: true
end
