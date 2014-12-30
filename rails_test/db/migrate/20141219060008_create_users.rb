class CreateUsers < ActiveRecord::Migration
  def change
    
    create_table :users do |t|
      t.binary   "email",               limit: 256, null: false
      t.string   "password",            limit: 128, null: false
      t.datetime "last_usage"
      t.string   "last_ip",             limit: 15
      t.string   "session_token",       limit: 32

      t.timestamps
    end
    add_index "users", ["email"], name: "idx_user_email", unique: true, using: :btree
    
    create_table :notes do |t|
      t.belongs_to :user
      
      t.string  "title",    limit: 256, null: false
      t.text    "content",  limit: 2147483647

      t.timestamps
    end
    
  end
end
