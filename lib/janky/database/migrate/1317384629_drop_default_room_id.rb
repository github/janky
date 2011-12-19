class DropDefaultRoomId < ActiveRecord::Migration
  def self.up
    change_column :repositories, :room_id, :integer, :default => nil, :null => true
  end

  def self.down
    change_column :repositories, :room_id, :integer, :default => 376289, :null => false
  end
end
