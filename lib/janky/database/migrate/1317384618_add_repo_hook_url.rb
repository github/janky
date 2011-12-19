class AddRepoHookUrl < ActiveRecord::Migration
  def self.up
    add_column :repositories, :hook_url, :string, :null => true
  end

  def self.down
    remove_column :repositories, :hook_url
  end
end
