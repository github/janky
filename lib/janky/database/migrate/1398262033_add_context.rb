class AddContext < ActiveRecord::Migration
  def self.up
    add_column :repositories, :context, :string, :null => true
  end

  def self.down
    remove_column :repositories, :context
  end
end
