class AddVoteAuditAndCache < ActiveRecord::Migration[5.2]
  def change
    create_table "vote_audits", force: :cascade do |t|
      t.integer "vote_id"
      t.integer "cached_votes_total", default: 0
      t.integer "cached_votes_score", default: 0
      t.integer "cached_votes_up", default: 0
      t.integer "cached_votes_down", default: 0
      t.integer "cached_weighted_score", default: 0
      t.integer "cached_weighted_total", default: 0
      t.float "cached_weighted_average", default: 0.0
      t.integer "cached_scoped_spam_votes_total", default: 0
      t.integer "cached_scoped_spam_votes_score", default: 0
      t.integer "cached_scoped_spam_votes_up", default: 0
      t.integer "cached_scoped_spam_votes_down", default: 0
      t.integer "cached_weighted_spam_score", default: 0
      t.integer "cached_weighted_spam_total", default: 0
      t.float "cached_weighted_spam_average", default: 0.0
      t.integer "cached_scoped_quality_votes_total", default: 0
      t.integer "cached_scoped_quality_votes_score", default: 0
      t.integer "cached_scoped_quality_votes_up", default: 0
      t.integer "cached_scoped_quality_votes_down", default: 0
      t.integer "cached_weighted_quality_score", default: 0
      t.integer "cached_weighted_quality_total", default: 0
      t.float "cached_weighted_quality_average", default: 0.0
    end

    create_table "vote_caches", force: :cascade do |t|
      t.string "resource_type"
      t.integer "resource_id"
      t.integer "cached_votes_total", default: 0
      t.integer "cached_votes_score", default: 0
      t.integer "cached_votes_up", default: 0
      t.integer "cached_votes_down", default: 0
      t.integer "cached_weighted_score", default: 0
      t.integer "cached_weighted_total", default: 0
      t.float "cached_weighted_average", default: 0.0
      t.integer "cached_scoped_spam_votes_total", default: 0
      t.integer "cached_scoped_spam_votes_score", default: 0
      t.integer "cached_scoped_spam_votes_up", default: 0
      t.integer "cached_scoped_spam_votes_down", default: 0
      t.integer "cached_weighted_spam_score", default: 0
      t.integer "cached_weighted_spam_total", default: 0
      t.float "cached_weighted_spam_average", default: 0.0
      t.integer "cached_scoped_quality_votes_total", default: 0
      t.integer "cached_scoped_quality_votes_score", default: 0
      t.integer "cached_scoped_quality_votes_up", default: 0
      t.integer "cached_scoped_quality_votes_down", default: 0
      t.integer "cached_weighted_quality_score", default: 0
      t.integer "cached_weighted_quality_total", default: 0
      t.float "cached_weighted_quality_average", default: 0.0
      t.integer "cached_scoped_interesting_votes_total", default: 0
      t.integer "cached_scoped_interesting_votes_score", default: 0
      t.integer "cached_scoped_interesting_votes_up", default: 0
      t.integer "cached_scoped_interesting_votes_down", default: 0
      t.integer "cached_weighted_interesting_score", default: 0
      t.integer "cached_weighted_interesting_total", default: 0
      t.float "cached_weighted_interesting_average", default: 0.0
      t.integer "cached_scoped_learnedfrom_votes_total", default: 0
      t.integer "cached_scoped_learnedfrom_votes_score", default: 0
      t.integer "cached_scoped_learnedfrom_votes_up", default: 0
      t.integer "cached_scoped_learnedfrom_votes_down", default: 0
      t.integer "cached_weighted_learnedfrom_score", default: 0
      t.integer "cached_weighted_learnedfrom_total", default: 0
      t.float "cached_weighted_learnedfrom_average", default: 0.0
      t.integer "cached_scoped_fun_votes_total", default: 0
      t.integer "cached_scoped_fun_votes_score", default: 0
      t.integer "cached_scoped_fun_votes_up", default: 0
      t.integer "cached_scoped_fun_votes_down", default: 0
      t.integer "cached_weighted_fun_score", default: 0
      t.integer "cached_weighted_fun_total", default: 0
      t.float "cached_weighted_fun_average", default: 0.0
      t.integer "cached_scoped_funny_votes_total", default: 0
      t.integer "cached_scoped_funny_votes_score", default: 0
      t.integer "cached_scoped_funny_votes_up", default: 0
      t.integer "cached_scoped_funny_votes_down", default: 0
      t.integer "cached_weighted_funny_score", default: 0
      t.integer "cached_weighted_funny_total", default: 0
      t.float "cached_weighted_funny_average", default: 0.0
      t.integer "cached_scoped_ad_votes_total", default: 0
      t.integer "cached_scoped_ad_votes_score", default: 0
      t.integer "cached_scoped_ad_votes_up", default: 0
      t.integer "cached_scoped_ad_votes_down", default: 0
      t.integer "cached_weighted_ad_score", default: 0
      t.integer "cached_weighted_ad_total", default: 0
      t.float "cached_weighted_ad_average", default: 0.0
      t.integer "cached_scoped_clickbait_votes_total", default: 0
      t.integer "cached_scoped_clickbait_votes_score", default: 0
      t.integer "cached_scoped_clickbait_votes_up", default: 0
      t.integer "cached_scoped_clickbait_votes_down", default: 0
      t.integer "cached_weighted_clickbait_score", default: 0
      t.integer "cached_weighted_clickbait_total", default: 0
      t.float "cached_weighted_clickbait_average", default: 0.0
      t.integer "cached_scoped_english_votes_total", default: 0
      t.integer "cached_scoped_english_votes_score", default: 0
      t.integer "cached_scoped_english_votes_up", default: 0
      t.integer "cached_scoped_english_votes_down", default: 0
      t.integer "cached_weighted_english_score", default: 0
      t.integer "cached_weighted_english_total", default: 0
      t.float "cached_weighted_english_average", default: 0.0
      t.integer "cached_scoped_fact_votes_total", default: 0
      t.integer "cached_scoped_fact_votes_score", default: 0
      t.integer "cached_scoped_fact_votes_up", default: 0
      t.integer "cached_scoped_fact_votes_down", default: 0
      t.integer "cached_weighted_fact_score", default: 0
      t.integer "cached_weighted_fact_total", default: 0
      t.float "cached_weighted_fact_average", default: 0.0
      t.decimal "cached_content_score", precision: 6, scale: 3
      t.integer "cached_content_votes_total"
      t.integer "cached_content_voters_total"
      t.integer "cached_content_interesting_up"
      t.integer "cached_content_interesting_down"
    end
  end
end