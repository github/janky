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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 1400144784) do

  create_table "branches", force: :cascade do |t|
    t.string   "name",          limit: 255, null: false
    t.integer  "repository_id", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "branches", ["name", "repository_id"], name: "index_branches_on_name_and_repository_id", unique: true, using: :btree

  create_table "builds", force: :cascade do |t|
    t.boolean  "green",                      default: false
    t.string   "url",          limit: 255
    t.string   "compare",      limit: 255,                   null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "commit_id",    limit: 4,                     null: false
    t.integer  "branch_id",    limit: 4,                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "output",       limit: 65535
    t.string   "room_id",      limit: 255
    t.string   "user",         limit: 255
    t.datetime "queued_at"
  end

  add_index "builds", ["branch_id"], name: "index_builds_on_branch_id", using: :btree
  add_index "builds", ["commit_id"], name: "index_builds_on_commit_id", using: :btree
  add_index "builds", ["completed_at"], name: "index_builds_on_completed_at", using: :btree
  add_index "builds", ["green"], name: "index_builds_on_green", using: :btree
  add_index "builds", ["started_at"], name: "index_builds_on_started_at", using: :btree
  add_index "builds", ["url"], name: "index_builds_on_url", unique: true, using: :btree

  create_table "commits", force: :cascade do |t|
    t.string   "sha1",          limit: 255,   null: false
    t.text     "message",       limit: 65535, null: false
    t.string   "author",        limit: 255,   null: false
    t.datetime "committed_at"
    t.integer  "repository_id", limit: 4,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url",           limit: 255,   null: false
  end

  add_index "commits", ["sha1", "repository_id"], name: "index_commits_on_sha1_and_repository_id", unique: true, using: :btree

  create_table "repositories", force: :cascade do |t|
    t.string   "name",           limit: 255,                null: false
    t.string   "uri",            limit: 255,                null: false
    t.string   "room_id",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "enabled",                    default: true, null: false
    t.string   "hook_url",       limit: 255
    t.integer  "github_team_id", limit: 4
    t.string   "job_template",   limit: 255
    t.string   "context",        limit: 255
  end

  add_index "repositories", ["enabled"], name: "index_repositories_on_enabled", using: :btree
  add_index "repositories", ["name"], name: "index_repositories_on_name", unique: true, using: :btree
  add_index "repositories", ["uri"], name: "index_repositories_on_uri", using: :btree

end
