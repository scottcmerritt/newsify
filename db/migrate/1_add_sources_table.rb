class AddSourcesTable < ActiveRecord::Migration[6.1]
  def change
   
  create_table "sources", force: :cascade do |t|
    t.bigint "org_id"
    t.text "title"
    t.text "description"
    t.text "url"
    t.bigint "url_blocked"
    t.text "urltoimage"
    t.datetime "published_at"
    t.bigint "createdby"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "hashkey"
    t.boolean "is_duplicate", default: false
    t.boolean "is_spam", default: false
    t.decimal "spam_score", precision: 5, scale: 4
    t.text "title_lemma"
    t.text "title_lemma_kw"
    t.text "descr_lemma"
    t.text "descr_lemma_kw"
    t.boolean "is_clickbait"
    t.boolean "is_ad"
    t.boolean "is_product"
    t.boolean "is_foreign"
    t.decimal "clickbait_score", precision: 5, scale: 4
    t.decimal "ad_score", precision: 5, scale: 4
    t.decimal "product_score", precision: 5, scale: 4
    t.decimal "foreign_score", precision: 5, scale: 4
    t.boolean "is_group", default: false
    t.integer "group_id"
    t.index ["descr_lemma"], name: "idx_16722_sources_descr_lemma_idx"
    t.index ["descr_lemma_kw"], name: "idx_16722_sources_descr_lemma_kw_idx"
    t.index ["description"], name: "idx_16722_sources_descr_idx"
    t.index ["hashkey"], name: "idx_16722_sources_hashkey_ix"
    t.index ["org_id"], name: "idx_16722_sources_org_id_ix"
    t.index ["published_at"], name: "idx_16722_sources_pub_at_idx"
    t.index ["title"], name: "idx_16722_sources_title_idx"
    t.index ["title_lemma"], name: "idx_16722_sources_title_lemma_idx"
    t.index ["title_lemma_kw"], name: "idx_16722_sources_title_lemma_kw_idx"
  end

  

   # importing data from api
       create_table :imports do |t|
      t.integer  :user_id
      t.string   :keyword
      t.integer  :api_id
      t.string   :description
      t.datetime :created_at
    end

     create_table :import_sources do |t|
      t.integer  :import_id
      t.integer  :source_id
      t.datetime :created_at
    end

  end

end