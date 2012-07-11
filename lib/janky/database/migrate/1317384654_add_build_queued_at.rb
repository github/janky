class AddBuildQueuedAt < ActiveRecord::Migration
  def self.up
    add_column :builds, :queued_at, :datetime, :null => true
    Janky::Build.started.each do |b|
      b.update_attributes!(:queued_at => b.created_at)
    end
  end

  def self.down
    remove_column :builds, :queued_at
  end
end
