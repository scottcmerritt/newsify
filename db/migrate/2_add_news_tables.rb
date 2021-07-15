class AddNewsTables < ActiveRecord::Migration[5.2]
  def change


  create_table "items", force: :cascade do |t|
    t.integer "mc_id"
    t.string "mc_guid", limit: 255
    t.string "name", limit: 255
    t.string "icon_css"

    # used for sorting
    t.decimal "relevance", precision: 4, scale: 3, default: "0.0"
    t.decimal "fame", precision: 4, scale: 3, default: "0.0"

    # for classifying/categorizing
    t.integer "template"
    t.string "itype", limit: 255
    t.integer "parent_id"
    t.string "isubtype", limit: 255

    t.integer "createdby"
    t.string "createdby_guid", limit: 255
    t.integer "user_id"
    t.integer "post_id"
    t.integer "idea_id"
    t.integer "tag_id"
    
    t.boolean "is_public", default: true
    t.boolean "is_pending", default: false
    t.boolean "approved", default: true
    t.boolean "is_global", default: false
    t.boolean "is_draft", default: false
    t.boolean "is_queued", default: false
    t.boolean "archived", default: false
    t.boolean "removed", default: false

    t.boolean "ambiguous"
    t.boolean "hide_user", default: false
    
    t.integer "upvote_count", default: 0
    t.integer "count_children"
    
    t.integer "hidden"
    t.boolean "has_tn"
    t.string "thumb", limit: 255
    t.string "img_url", limit: 255
    
    t.string "url", limit: 255

    t.integer "disambig_id"
    t.boolean "is_property", default: false
    t.boolean "is_item", default: true
    t.string "thumb2", limit: 255
    t.string "thumb_sq", limit: 255
    t.string "thumb2_sq", limit: 255

    t.string "wd_label", limit: 255
    t.string "wd_descr", limit: 255
    t.string "wiki_url", limit: 255
    t.string "wiki_img_url", limit: 255
    t.datetime "wiki_updated_at"
    t.string "wd_id", limit: 255
    t.datetime "wd_updated"
    t.text "wiki_text"

    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "publish_date"
    t.datetime "approved_at"
    t.integer "approved_by"
    t.datetime "archived_at"
    t.integer "archived_by"
    t.datetime "removed_at"
    t.integer "removed_by"

    t.string "url_fb", limit: 255
    t.string "url_twitter", limit: 255

    t.integer "sash_id"
    t.integer "level", default: 0
    t.integer "iptc_subject_code"
    t.index ["iptc_subject_code"], name: "iptc_subject_code"
  end


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
      t.string "icon_css"
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