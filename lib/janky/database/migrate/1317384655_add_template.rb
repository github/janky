class AddTemplate < ActiveRecord::Migration
  def self.up
    add_column :repositories, :job_template, :string, :null => true
  end

  def self.down
    remove_column :repositories, :job_template
  end
end
