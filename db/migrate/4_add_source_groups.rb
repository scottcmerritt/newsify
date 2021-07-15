class AddSourceGroups < ActiveRecord::Migration[5.2]
  def change
    create_table "source_groups", force: :cascade do |t|
      t.integer "source_id"
      t.integer "child_id"
      t.decimal "score", precision: 7, scale: 3
      t.integer "created_by"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end