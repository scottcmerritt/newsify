module Newsify
  class StatsController < ApplicationController
    # THIS IS A PUBLIC controller (for now)
    skip_before_action :authenticate_user!

    def index
      render json: {updated_at:Time.now.utc,info:site_info, stats:site_stats, activity: activity_stats}
    end

    private

    def site_info
      {name: translated_site_name,created_at:site_stat(:created_at),rows:site_stat(:rows)}
    end
    def site_stats
      {
        users:User.count,
        sources:Source.count,
        summaries:Summary.count,
        favorites: {sources:site_favorites(:sources),topics:site_favorites(:topics)}
       }
    end

    def site_favorites type
      case type
      when :sources
        top_sources
      when :topics
        top_topics #["Topic 1","Topic 2"]
      end
    end

    def site_stat type
      case type
      when :created_at
        User.order("created_at ASC").first.created_at
      when :rows
        Feedbacker::Stats.database_info[:rows][:used] if defined?(Feedbacker::Stats)
      end
    end

    def activity_stats
      info = [
      {
        name: "Feedback", count: ActsAsVotable::Vote.count
      },
      {
        name: "Items reviewed", count: Community::VoteAudit.count
      },
      {
        name: "Audits", count: ActsAsVotable::Vote.where("votable_type = ?","Community::VoteAudit").count
      },
      {
        name: "Reviewers", count: User.with_any_role(:moderator, :reviewer).count
      },
      {
        name: "Members", count: User.count
      },
      {
        name: "Active members", count: User.where("last_sign_in_at > ? OR current_sign_in_at > ?",7.days.ago,7.days.ago).count
      },
      {
        name: 'Recent views', count: Impression.where("created_at > ?", 7.days.ago).count
      },
      {
        name: 'Recent viewers', count: Impression.select("DISTINCT(ip_address)").where("created_at > ?", 7.days.ago).count
      },
      ]
    end

    def top_sources limit:4
      news_feed = Newsify::Feed.new(model:Newsify::Source,params:{label:"quality"},load:false,defaults:true) #,labels_all:(@mod_labels+@labels),sort_by:@sort_by)
      news_feed.filter!
      news_feed.data.limit(limit).to_json(only: [:id,:title,:hashkey,:urltoimage])
    end

    def top_topics limit:4
      news_feed = Newsify::Feed.new(model:Newsify::Item,params:{label:"quality"},load:false,defaults:true) #,labels_all:(@mod_labels+@labels),sort_by:@sort_by)
      news_feed.filter!
      news_feed.data.limit(limit).to_json(only: [:id,:name,:wiki_img_url])

    end

  end
end