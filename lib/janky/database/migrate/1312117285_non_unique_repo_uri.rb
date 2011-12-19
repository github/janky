class NonUniqueRepoUri < ActiveRecord::Migration
  def self.up
    remove_index :repositories, :uri
    add_index :repositories, :uri
  end

  def self.down
    add_index :repositories, :uri, :unique => true
  end
end
