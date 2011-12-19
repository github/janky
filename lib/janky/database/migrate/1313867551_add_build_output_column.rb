class AddBuildOutputColumn < ActiveRecord::Migration
  def self.up
    add_column :builds, :output, :text, :null => true, :default => nil
  end

  def self.down
    remove_column :builds, :output
  end
end
