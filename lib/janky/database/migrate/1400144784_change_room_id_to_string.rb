class ChangeRoomIdToString < ActiveRecord::Migration
  def change
    change_column :repositories, :room_id, :string
    change_column :builds, :room_id, :string
  end
end
