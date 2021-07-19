module Classify

class SimilarRows

	def initialize(attributes={})
		@items_idx = attributes[:items_idx]
		@rows = []

		@custom_timer = {}
		@feedback = []
	end

	def custom_timer key=nil
		if key.nil?
			@custom_timer.each_pair do |k,v|
				@custom_timer[k] = ActionController::Base.helpers.number_with_precision(v, :precision => 5,:delimiter=>",")
			end
			return @custom_timer
		else
			if @custom_timer.has_key?(key)
				@custom_timer[key]
			else
				0
			end
		end
	end
	def feedback
		@feedback
	end

	def rows
		@rows
	end
	def new_row item_key
		{:item=>@items_idx[item_key],:related=>nil,:pairs=>nil}
	end
	def add_row row
		@rows.push row
	end
	def sort_by_pair_count
		@rows = @rows.sort_by{|row| row[:pairs].length}.reverse
	end

	def tags_by_source source, row_index= nil

		ids = []
		tags = []
		item_ids = {}
		item_objs = {}
		all_tags = {}

		if !row_index.nil? && row_index.is_a?(Integer) && !@rows[row_index].nil? #[row_index][:item][:id]
			tags = Newsify::Source.cached_topics @rows[row_index][:item][:id]
		else
			#tags = Source.topics(@rows[row_index][:item][:id])
			tags = Newsify::Source.cached_topics source.id
		end

		tags.each do |tag|
			all_tags[tag.id] = {:item=>tag,:score=>tag.score}
		end

		return all_tags
	end

	def tags row_index

		ids = []
		tags = []
		item_ids = {}
		item_objs = {}

		#tags = Source.topics(@rows[row_index][:item][:id])
		tags = Newsify::Source.cached_topics @rows[row_index][:item][:id]
		all_tags = {}
		tags.each do |tag|
			all_tags[tag.id] = {:item=>tag,:score=>tag.score}
		end
		return all_tags

=begin
		@rows[row_index][:pairs].each do |row|
			ids.push row[:item][:id]
			_tags = Source.topics(row[:item][:id])
			tags+=_tags
		end

		uniq_tags = []
		tags.each do |tag|
			item_ids[tag.id] = item_ids.has_key?(tag.id) ? (item_ids[tag.id]+1) : 1
			item_objs[tag.id] = tag
		end

#		item_ids = Hash[item_ids.sort_by(|k,v| v).reverse]
		item_ids = item_ids.sort_by{|k,v| v}.reverse

		all_tags = []
		item_ids.each do |val|
			all_tags.push({:item=>item_objs[val[0]],:count=>val[1]})
		end
		

		#TODO: use reference articles to tag with broad categories
		# like politics, entertainment, business, etc...
		# headlines, breaking, trending

		return all_tags
=end
	end

	def suggest_items row_index
		logger = nil
		refresh_cache = false
		cache_expiration = 600000

		st = Time.now
		title = @rows[row_index][:item][:title]
		descr = @rows[row_index][:item][:description]

    	tag_options = {:description=>descr,:build_tags=>true,:with_scores=>true,:exclude_common_words=>true,:current_items=>[],:refresh_cache=>refresh_cache,:cache_expiration=>cache_expiration,:logger=>logger}
		tag_obj = Newsify::Summary.get_tag_suggestions title, tag_options


		et = Time.now
		@custom_timer["suggest_tags"] = 0 if !@custom_timer.has_key?("suggest_tags")
		@custom_timer["suggest_tags"]+=(et-st)
		
		# this adds the feedback to the page (it really slows down render)
		#@feedback+=tag_obj[:feedback]
		
		tag_obj[:timers].each_pair do |k,v|
			if @custom_timer.has_key?(k)
				@custom_timer[k]+=v
			else
				@custom_timer[k]=v
			end
		end

		# scores = {:item=>item_lookup[k],:score=>v,:words=>words_arr[k]}
		return tag_obj[:tags] #{:tags=>tags,:scores=>tags_obj[:scores]}
	end
end
end