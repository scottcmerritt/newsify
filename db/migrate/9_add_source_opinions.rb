class AddSourceOpinions < ActiveRecord::Migration[5.2]
  def change
    create_table "source_opinions", force: :cascade do |t|
      t.integer "source_id"
      t.integer "opinion_id"
      t.integer "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end