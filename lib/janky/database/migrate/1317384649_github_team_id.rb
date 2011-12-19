class GithubTeamId < ActiveRecord::Migration
  def self.up
    add_column :repositories, :github_team_id, :integer, :null => true
  end

  def self.down
    remove_column :repositories, :github_team_id
  end
end
