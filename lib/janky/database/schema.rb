# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 1400144784) do

  create_table "branches", :force => true do |t|
    t.string   "name",          :null => false
    t.integer  "repository_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "branches", ["name", "repository_id"], :name => "index_branches_on_name_and_repository_id", :unique => true

  create_table "builds", :force => true do |t|
    t.boolean  "green",        :default => false
    t.string   "url"
    t.string   "compare",                         :null => false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "commit_id",                       :null => false
    t.integer  "branch_id",                       :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.text     "output"
    t.string   "room_id"
    t.string   "user"
    t.datetime "queued_at"
  end

  add_index "builds", ["branch_id"], :name => "index_builds_on_branch_id"
  add_index "builds", ["commit_id"], :name => "index_builds_on_commit_id"
  add_index "builds", ["completed_at"], :name => "index_builds_on_completed_at"
  add_index "builds", ["green"], :name => "index_builds_on_green"
  add_index "builds", ["started_at"], :name => "index_builds_on_started_at"
  add_index "builds", ["url"], :name => "index_builds_on_url", :unique => true

  create_table "commits", :force => true do |t|
    t.string   "sha1",          :null => false
    t.text     "message",       :null => false
    t.string   "author",        :null => false
    t.datetime "committed_at"
    t.integer  "repository_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "url",           :null => false
  end

  add_index "commits", ["sha1", "repository_id"], :name => "index_commits_on_sha1_and_repository_id", :unique => true

  create_table "repositories", :force => true do |t|
    t.string   "name",                             :null => false
    t.string   "uri",                              :null => false
    t.string   "room_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "enabled",        :default => true, :null => false
    t.string   "hook_url"
    t.integer  "github_team_id"
    t.string   "job_template"
    t.string   "context"
  end

  add_index "repositories", ["enabled"], :name => "index_repositories_on_enabled"
  add_index "repositories", ["name"], :name => "index_repositories_on_name", :unique => true
  add_index "repositories", ["uri"], :name => "index_repositories_on_uri"

end
