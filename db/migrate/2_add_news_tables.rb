class AddNewsTables < ActiveRecord::Migration[5.2]
  def change

    create_table "authors", force: :cascade do |t|
      t.text "name"
      t.bigint "user_id"
      t.bigint "createdby"
      t.datetime "created_at"
      t.datetime "updated_at"
    end


    create_table "source_authors", force: :cascade do |t|
      t.bigint "source_id"
      t.bigint "author_id"
      t.decimal "contrib_score", precision: 5, scale: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["author_id"], name: "idx_16760_source_authors_author_id_ix"
      t.index ["source_id"], name: "idx_16760_source_authors_source_id_ix"
    end

    create_table "summaries", force: :cascade do |t|
      t.text "title"
      t.bigint "item_id"
      t.datetime "date"
      t.decimal "score", precision: 5, scale: 4
      t.datetime "created_at"
      t.datetime "updated_at"
      t.bigint "createdby"
      t.bigint "approvedby"
      t.bigint "source_chars"
      t.text "mc_guid"
      t.text "post_mc_guid"
      t.datetime "published_at"
      t.index ["mc_guid"], name: "idx_16695_summaries_mc_guid_idx"
      t.index ["post_mc_guid"], name: "idx_16695_summaries_post_mc_guid_idx"
    end


    create_table "summary_logs", force: :cascade do |t|
      t.bigint "summary_id"
      t.bigint "user_id"
      t.decimal "read_time", precision: 5, scale: 1
      t.boolean "skipped"
      t.datetime "read_at"
      t.datetime "logged_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "summary_sources", force: :cascade do |t|
      t.bigint "summary_id"
      t.bigint "source_id"
      t.decimal "contrib_score", precision: 5, scale: 4
      t.datetime "created_at"
      t.datetime "updated_at"
    end




    create_table "source_topics", force: :cascade do |t|
      t.bigint "source_id"
      t.bigint "item_id"
      t.bigint "createdby"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "approved_at"
      t.boolean "approved"
      t.bigint "approvedby"
      t.text "approvedby_guid"
      t.decimal "score", precision: 5, scale: 4
      t.index ["item_id"], name: "idx_16733_source_topics_item_id_ix"
      t.index ["source_id"], name: "idx_16733_source_topics_source_id_ix"
    end

    create_table "source_topics_removed", force: :cascade do |t|
      t.bigint "source_id"
      t.bigint "item_id"
      t.text "title"
      t.decimal "score", precision: 5, scale: 4
      t.boolean "active", default: true
      t.boolean "is_spam", default: false
      t.bigint "createdby"
      t.text "createdby_guid"
      t.boolean "approved"
      t.datetime "approved_at"
      t.bigint "approvedby"
      t.text "approvedby_guid"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "summary_items", force: :cascade do |t|
      t.bigint "summary_id"
      t.bigint "item_id"
      t.decimal "score", precision: 5, scale: 4
      t.bigint "createdby"
      t.bigint "approvedby"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "approved_at"
      t.boolean "approved"
      t.text "approvedby_guid"
    end

    create_table "summary_items_removed", force: :cascade do |t|
      t.bigint "summary_id"
      t.bigint "item_id"
      t.text "title"
      t.decimal "score", precision: 5, scale: 4
      t.boolean "active", default: true
      t.boolean "is_spam", default: false
      t.bigint "createdby"
      t.text "createdby_guid"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean "approved"
      t.datetime "approved_at"
      t.bigint "approvedby"
      t.text "approvedby_guid"
    end

    create_table "contents", force: :cascade do |t|
      t.bigint "source_id"
      t.text "title"
      t.text "article"
      t.text "misc"
      t.boolean "edited"
      t.bigint "edited_by"
      t.datetime "edited_on"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["source_id"], name: "idx_16784_contents_source_id_idx"
    end


  end
end