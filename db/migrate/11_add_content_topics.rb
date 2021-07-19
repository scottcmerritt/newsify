class AddContentTopics < ActiveRecord::Migration[5.2]
	def change
	  create_table "content_topics", force: :cascade do |t|
	    t.string "content_type"
	    t.bigint "content_id"
	    t.bigint "item_id"
	    t.bigint "createdby"
	    t.datetime "approved_at"
	    t.boolean "category", default: false
	    t.boolean "approved"
	    t.bigint "approvedby"
	    t.text "approvedby_guid"
	    t.decimal "score", precision: 5, scale: 4
	    t.integer "classifier"
	    t.integer "itype_id"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.index ["content_id"], name: "content_topics_content_id"
	    t.index ["content_type", "content_id", "item_id"], name: "content_topics_type_id_and_item_id", unique: true
	    t.index ["content_type"], name: "content_topics_content_type"
	    t.index ["item_id"], name: "content_topics_item_id"
	  end
	end
end