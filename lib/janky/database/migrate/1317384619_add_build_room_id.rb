class AddBuildRoomId < ActiveRecord::Migration
  def self.up
    add_column :builds, :room_id, :integer, :null => true
  end

  def self.down
    remove_column :builds, :room_id
  end
end
