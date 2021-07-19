class AddOpinions < ActiveRecord::Migration[5.2]
  def change
    create_table "opinions", force: :cascade do |t|
      t.string "title"
      t.text "description"
      t.integer "created_by"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end