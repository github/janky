$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))
ENV["RACK_ENV"] ||= "development"

require "janky"
Janky.setup(ENV)
require "janky/tasks"

task "db:seed" do
  if ENV["RACK_ENV"] != "development"
    fail "refusing to load seed data into non-development database"
  end

  dump = File.expand_path("../lib/janky/database/seed.dump.gz", __FILE__)

  Replicate::Loader.new do |loader|
    loader.log_to $stderr, false, false
    loader.read Zlib::GzipReader.open(dump)
  end
end

task :test do
  abort "Use script/test to run the test suite."
end
task :default => :test
