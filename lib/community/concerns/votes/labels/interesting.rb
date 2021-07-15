module Community
  module Votes
    module Labels
      module Interesting
  extend ActiveSupport::Concern

    def cached_scoped_interesting_votes_total
    	self.vote_cache.cached_scoped_interesting_votes_total
    end
    def cached_scoped_interesting_votes_total=(value)
    	self.vote_cache.cached_scoped_interesting_votes_total = value
    end
    def cached_scoped_interesting_votes_score
    	self.vote_cache.cached_scoped_interesting_votes_score
    end
    def cached_scoped_interesting_votes_score=(value)
    	self.vote_cache.cached_scoped_interesting_votes_score = value
    end
    def cached_scoped_interesting_votes_up
    	self.vote_cache.cached_scoped_interesting_votes_up
    end
    def cached_scoped_interesting_votes_up=(value)
    	self.vote_cache.cached_scoped_interesting_votes_up = value
    end
    def cached_scoped_interesting_votes_down
    	self.vote_cache.cached_scoped_interesting_votes_down
    end
    def cached_scoped_interesting_votes_down=(value)
    	self.vote_cache.cached_scoped_interesting_votes_down = value
    end
    def cached_weighted_interesting_total
    	self.vote_cache.cached_weighted_interesting_total
    end
    def cached_weighted_interesting_total=(value)
    	self.vote_cache.cached_weighted_interesting_total = value
    end
    def cached_weighted_interesting_score
    	self.vote_cache.cached_weighted_interesting_score
    end
    def cached_weighted_interesting_score=(value)
    	self.vote_cache.cached_weighted_interesting_score = value
    end
     def cached_weighted_interesting_average
    	self.vote_cache.cached_weighted_interesting_average
    end
    def cached_weighted_interesting_average=(value)
    	self.vote_cache.cached_weighted_interesting_average = value
    end
end
end
end
end