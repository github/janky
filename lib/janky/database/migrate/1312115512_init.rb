class Init < ActiveRecord::Migration
  def self.up
    create_table :repositories, :force => true do |t|
      t.string :name, :null => false
      t.string :uri,  :null => false
      t.integer :room_id, :null => false
      t.timestamps
    end
    add_index :repositories, :name, :unique => true
    add_index :repositories, :uri,  :unique => true

    create_table :branches, :force => true do |t|
      t.string     :name, :null => false
      t.belongs_to :repository, :null => false
      t.timestamps
    end
    add_index :branches, [:name, :repository_id], :unique => true

    create_table :commits, :force => true do |t|
      t.string :sha1,    :null => false
      t.string :message, :null   => false
      t.string :author,  :null   => false
      t.datetime :committed_at
      t.belongs_to :repository, :null => false
      t.timestamps
    end
    add_index :commits, [:sha1, :repository_id], :unique => true

    create_table :builds, :force => true do |t|
      t.boolean :green, :default => false
      t.string  :url, :null => true
      t.string  :compare, :null => false
      t.datetime :started_at
      t.datetime :completed_at
      t.belongs_to :commit, :null => false
      t.belongs_to :branch, :null => false
      t.timestamps
    end
    add_index :builds, :url, :unique => true
  end

  def self.down
    drop_table :repositories
    drop_table :branches
    drop_table :commits
    drop_table :builds
  end
end
