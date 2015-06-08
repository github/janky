class AddMoreBuildIndexes < ActiveRecord::Migration
  def self.up
    add_index :builds, :started_at
    add_index :builds, :completed_at
    add_index :builds, :green
  end

  def self.down
    remove_index :builds, :started_at
    remove_index :builds, :completed_at
    remove_index :builds, :green
  end
end
