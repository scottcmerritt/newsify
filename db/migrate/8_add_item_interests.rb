class AddItemInterests < ActiveRecord::Migration[5.2]
  def change
    create_table "item_interests", force: :cascade do |t|
      t.integer "item_id"
      t.integer "user_id"
      t.decimal "value", precision: 6, scale: 3
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "resource_type"
      t.integer "resource_id"
      t.index ["item_id", "user_id"], name: "idx_item_interests_on_item_id_and_user_id"
      t.index ["item_id"], name: "idx_item_interests_item_id"
    end
  end
end