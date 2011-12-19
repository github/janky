class RepoEnabled < ActiveRecord::Migration
  def self.up
    add_column :repositories, :enabled, :boolean, :null => false, :default => true
    add_index :repositories, :enabled
  end

  def self.down
    remove_column :repositories, :enabled
    remove_index :repositories, :enabled
  end
end
