class ChangeCommitMessageToText < ActiveRecord::Migration
  def change
    change_column :commits, :message, :text, :null => false
  end
end
