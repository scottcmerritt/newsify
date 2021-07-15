class AddUserAudits < ActiveRecord::Migration[5.2]
  def change
    create_table "user_audits", force: :cascade do |t|
      t.integer "user_id"
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
      t.integer "cached_scoped_fact_votes_total", default: 0
      t.integer "cached_scoped_fact_votes_score", default: 0
      t.integer "cached_scoped_fact_votes_up", default: 0
      t.integer "cached_scoped_fact_votes_down", default: 0
      t.integer "cached_weighted_fact_score", default: 0
      t.integer "cached_weighted_fact_total", default: 0
      t.float "cached_weighted_fact_average", default: 0.0
    end
  end
end