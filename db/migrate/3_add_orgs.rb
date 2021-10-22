class AddOrgs < ActiveRecord::Migration[5.2]
  def change

  create_table "org_users", force: :cascade do |t|
    t.integer "org_id"
    t.integer "user_id"
    t.integer "role_id"
    t.string "role_title"
    t.boolean "is_active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "role_details"
    t.text "whyjoined"
    t.boolean "approved", default: true
    t.datetime "approved_at"
    t.integer "approved_by"
    t.boolean "archived", default: false
    t.datetime "archived_at"
    t.integer "archived_by"
    t.boolean "removed", default: false
    t.datetime "removed_at"
    t.integer "removed_by"
    t.boolean "hide_user", default: false
    t.boolean "is_pending", default: false
    t.boolean "is_flagged", default: false
    t.index ["org_id"], name: "idx_user_orgs_org_id_ix"
    t.index ["user_id"], name: "idx_user_orgs_user_id_ix"
  end

  create_table "orgs", force: :cascade do |t|
    t.bigint "item_id"
    t.text "name"
    t.string "name_slug"
    t.text "url"
    t.text "urltoimage"
    t.bigint "image_id"
    t.text "newsapi_key"
    t.bigint "createdby"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "mc_guid", limit: 255
    t.integer "parent_id"
    t.integer "user_id"
    t.integer "promoter_org_id"
    t.boolean "is_promoter", default: false
    t.boolean "is_admin", default: false
    t.integer "county_id"
    t.integer "city_id"
    t.integer "state_id"
    t.integer "country_id"
    t.text "purpose"
    t.text "why_join"
    t.boolean "is_news", default: true
    t.boolean "is_blog", default: false
    t.boolean "is_group", default: false
    t.boolean "is_company", default: false
    t.boolean "is_non_profit", default: false
    t.boolean "approve_members", default: false
    t.integer "approval_type"
    t.integer "approval_group_id"
    t.string "icon_css"
    t.boolean "is_network", default: false
    t.integer "sash_id"
    t.integer "level", default: 0
    t.boolean "is_debate", default: false
    t.boolean "is_guest", default: false
    t.integer "surge_capacity", default: 15
    t.index ["city_id"], name: "index_orgs_on_city_id"
    t.index ["country_id"], name: "index_orgs_on_country_id"
    t.index ["county_id"], name: "index_orgs_on_county_id"
    t.index ["item_id"], name: "index_orgs_on_item_id"
    t.index ["parent_id"], name: "index_orgs_on_parent_id"
    t.index ["state_id"], name: "index_orgs_on_state_id"
    t.index ["user_id"], name: "index_orgs_on_user_id"
  end

  
  create_table "author_orgs", force: :cascade do |t|
    t.bigint "org_id"
    t.bigint "author_id"
    t.bigint "is_active"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_id"], name: "idx_16766_author_orgs_author_id_ix"
    t.index ["org_id"], name: "idx_16766_author_orgs_org_id_ix"
  end

	end
end