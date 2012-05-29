class AddBuildIndexes < ActiveRecord::Migration
  def self.up
    add_index :builds, :commit_id
    add_index :builds, :branch_id
  end

  def self.down
    remove_index :builds, :commit_id
    remove_index :builds, :branch_id
  end
end
