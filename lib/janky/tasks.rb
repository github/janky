require "rake"
require "rake/tasklib"

module Janky
  module Tasks
    extend Rake::DSL

    namespace :db do
      desc "Run the migration(s)"
      task :migrate do
        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate(migration_dir)

        Rake::Task["db:schema:dump"].invoke
      end

      desc 'Rolls the schema back to the previous version.'
      task :rollback do
        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.rollback(migration_dir, 1)

        Rake::Task["db:schema:dump"].invoke
      end

      namespace :schema do
        desc "Dump the database schema into a standard Rails schema.rb file"
        task :dump do
          require "active_record/schema_dumper"

          path = db_dir.join("schema.rb").to_s

          File.open(path, "w:utf-8") do |fd|
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, fd)
          end
        end
      end
    end

    def self.db_dir
      @db_dir ||= Pathname(__FILE__).expand_path.join("../database")
    end

    def self.migration_dir
      db_dir.join("migrate").to_s
    end
  end
end
