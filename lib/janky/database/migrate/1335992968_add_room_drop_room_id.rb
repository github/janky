class AddRoomDropRoomId < ActiveRecord::Migration
  def self.up
    add_column :builds, :room, :text, :null => true
    remove_column :builds, :room_id

    add_column :repositories, :room, :text, :null => true
    remove_column :repositories, :room_id
  end

  def self.down
    remove_column :builds, :room
    add_column :builds, :room_id, :integer, :null => true

    remove_column :repositories, :room
    add_column :repositories, :room_id, :integer, :null => true
  end
end
