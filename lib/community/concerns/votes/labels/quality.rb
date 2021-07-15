module Community
  module Votes
    module Labels
      module Quality
  extend ActiveSupport::Concern

    def cached_scoped_quality_votes_total
    	self.vote_cache.cached_scoped_quality_votes_total
    end
    def cached_scoped_quality_votes_total=(value)
    	self.vote_cache.cached_scoped_quality_votes_total = value
    end
    def cached_scoped_quality_votes_score
    	self.vote_cache.cached_scoped_quality_votes_score
    end
    def cached_scoped_quality_votes_score=(value)
    	self.vote_cache.cached_scoped_quality_votes_score = value
    end
    def cached_scoped_quality_votes_up
    	self.vote_cache.cached_scoped_quality_votes_up
    end
    def cached_scoped_quality_votes_up=(value)
    	self.vote_cache.cached_scoped_quality_votes_up = value
    end
    def cached_scoped_quality_votes_down
    	self.vote_cache.cached_scoped_quality_votes_down
    end
    def cached_scoped_quality_votes_down=(value)
    	self.vote_cache.cached_scoped_quality_votes_down = value
    end
    def cached_weighted_quality_total
    	self.vote_cache.cached_weighted_quality_total
    end
    def cached_weighted_quality_total=(value)
    	self.vote_cache.cached_weighted_quality_total = value
    end
    def cached_weighted_quality_score
    	self.vote_cache.cached_weighted_quality_score
    end
    def cached_weighted_quality_score=(value)
    	self.vote_cache.cached_weighted_quality_score = value
    end
     def cached_weighted_quality_average
    	self.vote_cache.cached_weighted_quality_average
    end
    def cached_weighted_quality_average=(value)
    	self.vote_cache.cached_weighted_quality_average = value
    end
end
end
end
end