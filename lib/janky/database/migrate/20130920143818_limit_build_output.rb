class LimitBuildOutput < ActiveRecord::Migration
  def self.up
    change_column :builds, :output, :text, :limit => 16777215
  end

  def self.down
    change_column :builds, :output, :text, :limit => nil
  end
end
