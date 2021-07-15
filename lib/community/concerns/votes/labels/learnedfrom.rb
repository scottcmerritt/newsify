module Community
  module Votes
    module Labels
      module LearnedFrom
  extend ActiveSupport::Concern

    def cached_scoped_learnedfrom_votes_total
    	self.vote_cache.cached_scoped_learnedfrom_votes_total
    end
    def cached_scoped_learnedfrom_votes_total=(value)
    	self.vote_cache.cached_scoped_learnedfrom_votes_total = value
    end
    def cached_scoped_learnedfrom_votes_score
    	self.vote_cache.cached_scoped_learnedfrom_votes_score
    end
    def cached_scoped_learnedfrom_votes_score=(value)
    	self.vote_cache.cached_scoped_learnedfrom_votes_score = value
    end
    def cached_scoped_learnedfrom_votes_up
    	self.vote_cache.cached_scoped_learnedfrom_votes_up
    end
    def cached_scoped_learnedfrom_votes_up=(value)
    	self.vote_cache.cached_scoped_learnedfrom_votes_up = value
    end
    def cached_scoped_learnedfrom_votes_down
    	self.vote_cache.cached_scoped_learnedfrom_votes_down
    end
    def cached_scoped_learnedfrom_votes_down=(value)
    	self.vote_cache.cached_scoped_learnedfrom_votes_down = value
    end
    def cached_weighted_learnedfrom_total
    	self.vote_cache.cached_weighted_learnedfrom_total
    end
    def cached_weighted_learnedfrom_total=(value)
    	self.vote_cache.cached_weighted_learnedfrom_total = value
    end
    def cached_weighted_learnedfrom_score
    	self.vote_cache.cached_weighted_learnedfrom_score
    end
    def cached_weighted_learnedfrom_score=(value)
    	self.vote_cache.cached_weighted_learnedfrom_score = value
    end
     def cached_weighted_learnedfrom_average
    	self.vote_cache.cached_weighted_learnedfrom_average
    end
    def cached_weighted_learnedfrom_average=(value)
    	self.vote_cache.cached_weighted_learnedfrom_average = value
    end
end
end
end
end