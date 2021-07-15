module Community
  module Votes
    module Labels
      module Fun
  extend ActiveSupport::Concern

    def cached_scoped_fun_votes_total
    	self.vote_cache.cached_scoped_fun_votes_total
    end
    def cached_scoped_fun_votes_total=(value)
    	self.vote_cache.cached_scoped_fun_votes_total = value
    end
    def cached_scoped_fun_votes_score
    	self.vote_cache.cached_scoped_fun_votes_score
    end
    def cached_scoped_fun_votes_score=(value)
    	self.vote_cache.cached_scoped_fun_votes_score = value
    end
    def cached_scoped_fun_votes_up
    	self.vote_cache.cached_scoped_fun_votes_up
    end
    def cached_scoped_fun_votes_up=(value)
    	self.vote_cache.cached_scoped_fun_votes_up = value
    end
    def cached_scoped_fun_votes_down
    	self.vote_cache.cached_scoped_fun_votes_down
    end
    def cached_scoped_fun_votes_down=(value)
    	self.vote_cache.cached_scoped_fun_votes_down = value
    end
    def cached_weighted_fun_total
    	self.vote_cache.cached_weighted_fun_total
    end
    def cached_weighted_fun_total=(value)
    	self.vote_cache.cached_weighted_fun_total = value
    end
    def cached_weighted_fun_score
    	self.vote_cache.cached_weighted_fun_score
    end
    def cached_weighted_fun_score=(value)
    	self.vote_cache.cached_weighted_fun_score = value
    end
     def cached_weighted_fun_average
    	self.vote_cache.cached_weighted_fun_average
    end
    def cached_weighted_fun_average=(value)
    	self.vote_cache.cached_weighted_fun_average = value
    end
end
end
end
end