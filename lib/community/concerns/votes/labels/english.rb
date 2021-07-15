module Community
  module Votes
    module Labels
      module English
  extend ActiveSupport::Concern

    def cached_scoped_english_votes_total
    	self.vote_cache.cached_scoped_english_votes_total
    end
    def cached_scoped_english_votes_total=(value)
    	self.vote_cache.cached_scoped_english_votes_total = value
    end
    def cached_scoped_english_votes_score
    	self.vote_cache.cached_scoped_english_votes_score
    end
    def cached_scoped_english_votes_score=(value)
    	self.vote_cache.cached_scoped_english_votes_score = value
    end
    def cached_scoped_english_votes_up
    	self.vote_cache.cached_scoped_english_votes_up
    end
    def cached_scoped_english_votes_up=(value)
    	self.vote_cache.cached_scoped_english_votes_up = value
    end
    def cached_scoped_english_votes_down
    	self.vote_cache.cached_scoped_english_votes_down
    end
    def cached_scoped_english_votes_down=(value)
    	self.vote_cache.cached_scoped_english_votes_down = value
    end
    def cached_weighted_english_total
    	self.vote_cache.cached_weighted_english_total
    end
    def cached_weighted_english_total=(value)
    	self.vote_cache.cached_weighted_english_total = value
    end
    def cached_weighted_english_score
    	self.vote_cache.cached_weighted_english_score
    end
    def cached_weighted_english_score=(value)
    	self.vote_cache.cached_weighted_english_score = value
    end
     def cached_weighted_english_average
    	self.vote_cache.cached_weighted_english_average
    end
    def cached_weighted_english_average=(value)
    	self.vote_cache.cached_weighted_english_average = value
    end
end
end
end
end