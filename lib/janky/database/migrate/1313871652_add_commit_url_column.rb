class AddCommitUrlColumn < ActiveRecord::Migration
  def self.up
    add_column :commits, :url, :string, :null => false
  end

  def self.down
    remove_column :commits, :url
  end
end
