class AddGuessScopes < ActiveRecord::Migration[5.2]
  def change
    create_table "guess_scopes", force: :cascade do |t|
      t.string "target_type"
      t.integer "target_id"
      t.integer "user_id"
      t.string "scope"
      t.decimal "score", precision: 9, scale: 4
      t.integer "guesser_id"
      t.boolean "accurate"
      t.string "reason"
      t.datetime "published_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["target_id", "target_type"], name: "idx_guess_scopes_on_target_id_and_type"
      t.index ["user_id"], name: "idx_guess_scopes_user_id"
    end
  end
end