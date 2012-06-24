class AddBuildPusher < ActiveRecord::Migration
  def self.up
    add_column :builds, :user, :string, :null => true
  end

  def self.down
    remove_column :builds, :user
  end
end
