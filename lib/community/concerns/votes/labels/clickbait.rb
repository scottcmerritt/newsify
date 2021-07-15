module Community
  module Votes
    module Labels
      module Clickbait
  extend ActiveSupport::Concern

    def cached_scoped_clickbait_votes_total
    	self.vote_cache.cached_scoped_clickbait_votes_total
    end
    def cached_scoped_clickbait_votes_total=(value)
    	self.vote_cache.cached_scoped_clickbait_votes_total = value
    end
    def cached_scoped_clickbait_votes_score
    	self.vote_cache.cached_scoped_clickbait_votes_score
    end
    def cached_scoped_clickbait_votes_score=(value)
    	self.vote_cache.cached_scoped_clickbait_votes_score = value
    end
    def cached_scoped_clickbait_votes_up
    	self.vote_cache.cached_scoped_clickbait_votes_up
    end
    def cached_scoped_clickbait_votes_up=(value)
    	self.vote_cache.cached_scoped_clickbait_votes_up = value
    end
    def cached_scoped_clickbait_votes_down
    	self.vote_cache.cached_scoped_clickbait_votes_down
    end
    def cached_scoped_clickbait_votes_down=(value)
    	self.vote_cache.cached_scoped_clickbait_votes_down = value
    end
    def cached_weighted_clickbait_total
    	self.vote_cache.cached_weighted_clickbait_total
    end
    def cached_weighted_clickbait_total=(value)
    	self.vote_cache.cached_weighted_clickbait_total = value
    end
    def cached_weighted_clickbait_score
    	self.vote_cache.cached_weighted_clickbait_score
    end
    def cached_weighted_clickbait_score=(value)
    	self.vote_cache.cached_weighted_clickbait_score = value
    end
     def cached_weighted_clickbait_average
    	self.vote_cache.cached_weighted_clickbait_average
    end
    def cached_weighted_clickbait_average=(value)
    	self.vote_cache.cached_weighted_clickbait_average = value
    end
end
end
end
end