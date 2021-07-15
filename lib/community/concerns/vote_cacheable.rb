# compatiable with ActsAsVotable so any table can be cached
module Community
module VoteCacheable
  extend ActiveSupport::Concern
  include Community::Votes::Labels # spam, quality, interesting, learnedfrom, fun, funny, ad, clickbait, english
  
    included do
        after_save :save_vote_cache
    end
    

	def save_vote_cache
		@vote_cache.save unless @vote_cache.nil?
	end

   def default_conditions
      {
        resource_id: self.id,
        resource_type: self.class.base_class.name.to_s
      }
    end

    def vote_cache
    	#@vote_cache = VoteCache.where(self.default_conditions).first_or_create if @vote_cache.nil?
        @vote_cache = VoteCache.where({
        resource_id: self.id,
        resource_type: self.class.base_class.name.to_s
      }).first_or_create if @vote_cache.nil?
    	@vote_cache
    end

    def cached_content_score
        self.vote_cache.cached_content_score
    end
    def cached_content_score=(value)
        self.vote_cache.cached_content_score = value
    end

    def cached_content_votes_total
        self.vote_cache.cached_content_votes_total
    end
    def cached_content_votes_total=(value)
        self.vote_cache.cached_content_votes_total = value
    end

    def cached_content_voters_total
        self.vote_cache.cached_content_voters_total
    end
    def cached_content_voters_total=(value)
        self.vote_cache.cached_content_voters_total = value
    end

    def cached_content_interesting_up
        self.vote_cache.cached_content_interesting_up
    end
    def cached_content_interesting_up=(value)
        self.vote_cache.cached_content_interesting_up = value
    end
    def cached_content_interesting_down
        self.vote_cache.cached_content_interesting_down
    end

    def cached_content_interesting_down=(value)
        self.vote_cache.cached_content_interesting_down = value
    end

    
    def cached_votes_total
    	self.vote_cache.cached_votes_total
    end
    def cached_votes_total=(value)
    	self.vote_cache.cached_votes_total = value
    end

    def cached_votes_score
    	self.vote_cache.cached_votes_score
    end
    def cached_votes_score=(value)
    	self.vote_cache.cached_votes_score = value
    end

    def cached_votes_up
    	self.vote_cache.cached_votes_up
    end
    def cached_votes_up=(value)
    	self.vote_cache.cached_votes_up = value
    end

    def cached_votes_down
    	self.vote_cache.cached_votes_down
    end
    def cached_votes_down=(value)
    	self.vote_cache.cached_votes_down = value
    end

    def cached_weighted_score
    	self.vote_cache.cached_weighted_score
    end
    def cached_weighted_score=(value)
    	self.vote_cache.cached_weighted_score = value
    end

    def cached_weighted_total
    	self.vote_cache.cached_weighted_total
    end
    def cached_weighted_total=(value)
    	self.vote_cache.cached_weighted_total = value
    end

    def cached_weighted_average
    	self.vote_cache.cached_weighted_average
    end
    def cached_weighted_average=(value)
    	self.vote_cache.cached_weighted_average = value
    end


     def scope_cache_field(field, vote_scope)
      return field if vote_scope.nil?

      case field
      when :cached_votes_total=
        "cached_scoped_#{vote_scope}_votes_total="
      when :cached_votes_total
        "cached_scoped_#{vote_scope}_votes_total"
      when :cached_votes_up=
        "cached_scoped_#{vote_scope}_votes_up="
      when :cached_votes_up
        "cached_scoped_#{vote_scope}_votes_up"
      when :cached_votes_down=
        "cached_scoped_#{vote_scope}_votes_down="
      when :cached_votes_down
        "cached_scoped_#{vote_scope}_votes_down"
      when :cached_votes_score=
        "cached_scoped_#{vote_scope}_votes_score="
      when :cached_votes_score
        "cached_scoped_#{vote_scope}_votes_score"
      when :cached_weighted_total
        "cached_weighted_#{vote_scope}_total"
      when :cached_weighted_total=
        "cached_weighted_#{vote_scope}_total="
      when :cached_weighted_score
        "cached_weighted_#{vote_scope}_score"
      when :cached_weighted_score=
        "cached_weighted_#{vote_scope}_score="
      when :cached_weighted_average
        "cached_weighted_#{vote_scope}_average"
      when :cached_weighted_average=
        "cached_weighted_#{vote_scope}_average="
      end
    end

    def update_cached_votes!(vote_scope = nil)
        self.vote_cache

      updates = {}

      if self.respond_to?(:cached_votes_total=)
        updates[:cached_votes_total] = count_votes_total(true)
      end

      if self.respond_to?(:cached_votes_up=)
        updates[:cached_votes_up] = count_votes_up(true)
      end

      if self.respond_to?(:cached_votes_down=)
        updates[:cached_votes_down] = count_votes_down(true)
      end

      if self.respond_to?(:cached_votes_score=)
        updates[:cached_votes_score] = (
          (updates[:cached_votes_up] || count_votes_up(true)) -
          (updates[:cached_votes_down] || count_votes_down(true))
        )
      end

      if self.respond_to?(:cached_weighted_total=)
        updates[:cached_weighted_total] = weighted_total(true)
      end

      if self.respond_to?(:cached_weighted_score=)
        updates[:cached_weighted_score] = weighted_score(true)
      end

      if self.respond_to?(:cached_weighted_average=)
        updates[:cached_weighted_average] = weighted_average(true)
      end

      if vote_scope
        if self.respond_to?(scope_cache_field :cached_votes_total=, vote_scope)
          updates[scope_cache_field :cached_votes_total, vote_scope] = count_votes_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_up=, vote_scope)
          updates[scope_cache_field :cached_votes_up, vote_scope] = count_votes_up(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_down=, vote_scope)
          updates[scope_cache_field :cached_votes_down, vote_scope] = count_votes_down(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_total=, vote_scope)
          updates[scope_cache_field :cached_weighted_total, vote_scope] = weighted_total(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_weighted_score=, vote_scope)
          updates[scope_cache_field :cached_weighted_score, vote_scope] = weighted_score(true, vote_scope)
        end

        if self.respond_to?(scope_cache_field :cached_votes_score=, vote_scope)
          updates[scope_cache_field :cached_votes_score, vote_scope] = (
            (updates[scope_cache_field :cached_votes_up, vote_scope] || count_votes_up(true, vote_scope)) -
            (updates[scope_cache_field :cached_votes_down, vote_scope] || count_votes_down(true, vote_scope))
          )
        end

        if self.respond_to?(scope_cache_field :cached_weighted_average=, vote_scope)
          updates[scope_cache_field :cached_weighted_average, vote_scope] = weighted_average(true, vote_scope)
        end
      end
      updates.each do |update,val|
        self.send(update.to_s+"=",val) #if update.to_s.include?("=")
      end
      #self.send(acts_as_votable_options[:cacheable_strategy], updates) if updates.size > 0
        
        self.save_vote_cache
        return updates.to_a

    end

    # counting
    def count_votes_total(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_votes_total, vote_scope) do
        find_votes_for(scope_or_empty_hash(vote_scope)).count
      end
    end

    def count_votes_up(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_votes_up, vote_scope) do
        get_up_votes(vote_scope: vote_scope).count
      end
    end

    def count_votes_down(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_votes_down, vote_scope) do
        get_down_votes(vote_scope: vote_scope).count
      end
    end

    def count_votes_score(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_votes_score, vote_scope) do
        ups = count_votes_up(true, vote_scope)
        downs = count_votes_down(true, vote_scope)
        ups - downs
      end
    end

    def weighted_total(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_weighted_total, vote_scope) do
        ups = get_up_votes(vote_scope: vote_scope).sum(:vote_weight)
        downs = get_down_votes(vote_scope: vote_scope).sum(:vote_weight)
        ups + downs
      end
    end

    def weighted_score(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_weighted_score, vote_scope) do
        ups = get_up_votes(vote_scope: vote_scope).sum(:vote_weight)
        downs = get_down_votes(vote_scope: vote_scope).sum(:vote_weight)
        ups - downs
      end
    end

    def weighted_average(skip_cache = false, vote_scope = nil)
      from_cache(skip_cache, :cached_weighted_average, vote_scope) do
        count = count_votes_total(skip_cache, vote_scope).to_i
        if count > 0
          weighted_score(skip_cache, vote_scope).to_f / count
        else
          0.0
        end
      end
    end

    private

    def from_cache(skip_cache, cached_method, vote_scope)
      if !skip_cache && respond_to?(scope_cache_field(cached_method, vote_scope))
        send(scope_cache_field(cached_method, vote_scope))
      else
        yield
      end
    end
end
end