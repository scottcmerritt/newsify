module Community
  module VoteStats
  CACHED_VOTE_COLS = ["cached_votes_total","cached_votes_up","cached_votes_down","cached_votes_score","cached_weighted_score","cached_weighted_total","cached_weighted_average"]
  extend ActiveSupport::Concern

    # this is a method thats called when you include the module in a class.
    def self.included(base)
      base.extend ClassMethods
    end



    module ClassMethods
       def update_all_interest_scores! minutes_ago: 30
        UserCustom.outdated_interests(minutes_ago: minutes_ago).each do |user|
          Newsify::ItemInterest.calc_interests! user, remove: true
        end
      end
    end

    def voting_since
      first_vote = self.find_votes.order("created_at ASC").first
      first_vote.created_at unless first_vote.nil?
    end

    # creates or gets a record for a user to be audited (i.e. evaluated)
    def auditable
      Community::UserAudit.where(user_id: self.id).first_or_create
    end
    def auditables
      Community::UserAudit.where(user_id: self.id)
    end

    def audited_count
      self.auditable.find_votes_for.count
      #ActsAsVotable::Vote.where("votable_type = ? AND votable_id = ?","Community::UserAudit",self.auditable.id).count
    end

    def vote_quality_score
      self.find_votes.select(CACHED_VOTE_COLS.map{|col| "SUM(#{col}) as #{col}"}.join(","))
      .joins("LEFT JOIN vote_audits ON vote_audits.vote_id = votes.id")
    end

    def vote_quality_scores
      # "cached_votes_total,cached_votes_score,cached_weighted_score,cached_weighted_total,cached_weighted_average"
      self.find_votes.select(CACHED_VOTE_COLS.join(",")).joins("LEFT JOIN vote_audits ON vote_audits.vote_id = votes.id")

    end

    def audits_performed
      self.find_votes_for_class(Community::VoteAudit).count
    end

    # total ratings (some objects can be rated multiple times, i.e interesting + quality + funny)
    def ratings klass
      self.find_votes_for_class(klass).count
    end
    def ratings_within klass, within_hrs = 4
      filter = {created_at: (Time.now - within_hrs.hours)..Time.now}
      self.find_votes_for_class(klass,filter).count
    end

    # distinct OBJECTS rated
    def rated klass
      self.find_votes_for_class(klass).select("votable_id").distinct.count
    end

    def rated_within klass, within_hrs = 4
      filter = {created_at: (Time.now - within_hrs.hours)..Time.now}
      self.find_votes_for_class(klass,filter).select("votable_id").distinct.count
    end

    def ratings_up_votes klass, within_hrs=4, label = nil
      filter = {created_at: (Time.now - within_hrs.hours)..Time.now}
      filter = filter.merge({vote_scope: label}) unless label.nil?

      self.find_up_votes_for_class(klass,filter).count
    end
    def ratings_down_votes klass, within_hrs=4, label = nil
      filter = {created_at: (Time.now - within_hrs.hours)..Time.now}
      filter = filter.merge({vote_scope: label}) unless label.nil?

      self.find_down_votes_for_class(klass,filter).count
    end

  end
end