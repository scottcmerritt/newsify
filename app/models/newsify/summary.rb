module Newsify
class Summary < ActiveRecord::Base #AbstractModel # adding an abstract class did not work with acts_as_votable
	self.table_name = "summaries"
	#has_paper_trail
	#acts_as_votable
	#include GenericObj, TextUtil, NewsManager, IconUtil
	#include VoteCacheable

	after_create :save_source_ids
	

	attribute :source_ids

	has_many :summary_sources, dependent: :destroy

	scope :with_orgs, -> {joins("LEFT JOIN orgs ON orgs.id = sources.org_id")}
	scope :with_sources, -> {joins("LEFT JOIN summary_sources ON summary_sources.summary_id=summaries.id").joins("LEFT JOIN sources ON summary_sources.source_id=sources.id")}
	scope :with_summary_items, -> {joins("LEFT JOIN summary_items ON summaries.id=summary_items.summary_id")}
	
	TOKEN_REGEXP = /^[a-z]+$|^\w+\-\w+|^[a-z]+[0-9]+[a-z]+$|^[0-9]+[a-z]+|^[a-z]+[0-9]+$/ 
   	
	def save_source_ids
		unless self.source_ids.nil?
			self.source_ids = [self.source_ids.to_i] if self.source_ids.is_a?(String)
			
			self.source_ids.each do |source_id|
				if !SummarySource.exists?(summary_id: self.id,source_id: source_id)
					ss = SummarySource.new(summary_id: self.id,source_id: source_id)
					ss.save
				end
			end
		end
	end

	def summaryDateLocal
		if self.date
			self.date
		else
			self.SummariesDate
		end
	end

	def sources
		Source.articles_by_summary_id self.id
		#Source.by_summary_id(self.id)
	end
	def self.recent limit=20,offset=0
		 Summary.select("items.name,summaries.*,summary_sources.source_id,sources.org_id,sources.title as source_title,orgs.name as source_name")
  		  	.joins("LEFT JOIN items ON items.id = summaries.item_id")
	      	.joins("LEFT JOIN summary_sources ON summary_sources.summary_id = summaries.id")
	      	.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
	      	.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
  			.order("date DESC")
  			.limit(limit)
  			.offset(offset)
	end

	def self.clear_duplicate_items limit=10,offset=0
		summaries = Summary.limit(limit).offset(0)
		.order("id DESC")
		summaries.each do |summary|
			summary.clear_duplicate_items
		end
	end
	def clear_duplicate_items
		sis = SummaryItem.where("summary_id = ?",self.id)
		si_list = []
		sis.each do |si|
			if si_list.include?(si.item_id)
				si.destroy
			else
				si_list.push(si.item_id)
			end
		end
	end

	def self.get_by_post_mc_guid post_mc_guid
		Summary.where("post_mc_guid = ?",post_mc_guid).first
	end
	def self.get_by_post_mc_guids post_mc_guids
		Summary.where("post_mc_guid IN (?)",post_mc_guids)
		.order("summaries.published_at DESC")
	end

	
	def self.get_by_id id
		 Summary.select("items.name,summaries.*,summary_sources.source_id,sources.org_id,sources.title as source_title,orgs.name as source_name")
  		  	.joins("LEFT JOIN items ON items.id = summaries.item_id")
	      	.joins("LEFT JOIN summary_sources ON summary_sources.summary_id = summaries.id")
	      	.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
	      	.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
	      	.where("summaries.id = ?",id).first
	end

	def item_ids
		return SummaryItem.select("item_id")
		.where("summary_id=?",self.id).pluck(:item_id)
	end

	def items
		return SummaryItem.select("summary_items.id as si_id,items.id as item_id, items.name as item_name")
		.joins("LEFT JOIN items ON summary_items.item_id=items.id")
		.where("summary_id=?",self.id)
	end

	def self.remote_post_summary share_item, share_data,logger=nil, use_ssl=true

      item_params = {}
      item_params[:content] = share_item.source_title
      item_params[:details] = share_item.title
      item_params[:details]+="\n\nFrom: " + share_item.source_name+"\n"
      item_params[:details]+=share_item.source_title+"\n\n"

      time_saved = Content.time_saved share_item
      if time_saved[:status]
        item_params[:details]+=time_saved[:text]
      end

      item_params[:tag_id] 	= share_data[:tag_id]
      item_params[:user_id] = share_data[:user_id]
      item_params[:token] 	= share_data[:token]

      item_params[:summary_mc_guid] = share_data[:mc_guid]
      

      #@item_params["mc_id"] = @share_item.id

      output = ApiData.share_summary(share_data[:post_url],item_params, share_data[:site_id], logger, use_ssl)
      return output
  	end

	def self.add title, createdby, date, item_ids=[], char_length = nil
		require 'securerandom'

		result = {:summary=>nil,:summary_items=>[]}
		item_id = !item_ids.nil? && item_ids.length>0 ? item_ids[0] : nil
		new_summary = Summary.new(:title=>title,:date=>date,:createdby=>createdby,:item_id=>item_id)
		
		new_summary.mc_guid = SecureRandom.uuid
		
		if !char_length.nil? && char_length > 0
			new_summary.source_chars = char_length
		end
		if new_summary.save
			result[:summary] = new_summary
			added_items = []
			if !item_ids.nil? && item_ids.length > 0
				item_ids.each do |item_id|
					if !added_items.include?(item_id)
						new_si = SummaryItem.add(:summary_id=>new_summary.id,:createdby=>createdby,:item_id=>item_id)
						result[:summary_items].push new_si
						added_items.push item_id
					end
				end
			end
		end
		return result
	end

	def self.update_title id, title
		si = Summary.where("id = ?", id).first
		si.title = title
		if si.save
			return true
		else
			return false
		end
	end

	def self.link_status summary_id, item_ids
		status = {}
		ids = select("summaries.item_id as id1,summary_items.item_id as id2")
		.joins("LEFT JOIN summary_items ON summary_items.summary_id = summaries.id")
		.where("(summaries.id = ?) OR (summary_id= ?)",summary_id,summary_id)

		ids.each do |id_row|
			status[id_row.id1] = item_ids.include? id_row.id1 unless id_row.id1.nil?
			status[id_row.id2] = item_ids.include? id_row.id2 unless id_row.id2.nil?
		end
		return status 
	end

	def self.by_item item_id, date=nil

		db_adapt = ActiveRecord::Base.configurations[Rails.env]['adapter']

		#if by_period == "month"
		#	if db_adapt == "sqlite3"
		#		sqlquery = "select strftime('%Y-%m', #{field_name}) as time_period,COUNT(id) as create_count FROM #{table_name} group by strftime('%Y-%m', #{field_name}) ORDER BY #{field_name} DESC LIMIT #{limit}"
		#	else
		#		#sqlquery = "select CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(date_part('month',#{field_name}),'MM')) as time_period,COUNT(id) as create_count from #{table_name} group by CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(date_part('month',#{field_name}),'MM')) ORDER BY CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(date_part('month',#{field_name}),'MM')) DESC LIMIT #{limit}"
		#		sqlquery = "select CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(#{field_name},'MM')) as time_period,COUNT(id) as create_count from #{table_name} group by CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(#{field_name},'MM')) ORDER BY CONCAT(date_part('year',#{field_name}), '-',TO_CHAR(#{field_name},'MM')) DESC LIMIT #{limit}"
		#	end

		if db_adapt == "sqlite3"

			if date.nil?
			select("summaries.id,summary_items.item_id,summary_sources.source_id,summaries.title,orgs.name as source_name,strftime('%Y-%m-%d',datetime(summaries.date, 'localtime')) as 'SummariesDate'")
			.joins("LEFT JOIN summary_items ON summaries.id = summary_items.summary_id")
			.joins("LEFT JOIN summary_sources ON summaries.id = summary_sources.summary_id")
			.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
			.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			.where("summaries.item_id = ? OR summary_items.item_id = ?",item_id,item_id)
			.order("date DESC")

			else
			formatted_date = date.strftime('%Y-%m-%d') #,date)
			logger.debug formatted_date
			select("summaries.id,summary_items.item_id,summary_sources.source_id,summaries.title,orgs.name as source_name,strftime('%Y-%m-%d',datetime(summaries.date, 'localtime')) as 'SummariesDate'")
			.joins("LEFT JOIN summary_sources ON summaries.id = summary_sources.summary_id")
			.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
			.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			.where("summaries.item_id = ? AND SummariesDate = ?",item_id,formatted_date)
			.order("date DESC")
			end

		else
			if date.nil?
				select("summaries.id,summary_items.item_id,summary_sources.source_id,summaries.title,orgs.name as source_name,summaries.date")
				.joins("LEFT JOIN summary_items ON summaries.id = summary_items.summary_id")
				.joins("LEFT JOIN summary_sources ON summaries.id = summary_sources.summary_id")
				.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
				.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
				.where("summaries.item_id = ? OR summary_items.item_id = ?",item_id,item_id)
				.order("date DESC")
			else

			end




		end


	end



	

    # some article titles have - [org_name] at the end.
    # we don't want to auto-tag the item because we ALREADY know the source org
    def self.remove_org_name title,item_id

    	names = Item.get_names_and_synonyms(item_id)

    	names.each do |name|
    		search_for = "- " + name
    		logger.debug search_for
	    	loc = title.downcase.index(search_for.downcase) # ("/ #{search_for} / i") 
	    	if !loc.nil? && loc > 0
	    		title = title[0..loc-1]
	    	end
	    end

	    return title
    end

    # removes punctuation, removes 's and removes common words like who, what, where, etc...
    def self.parse_into_words title, exclude_commom_words = false
    	if title.nil?
    		return []
    	else
	    	cw = exclude_commom_words ? ["who","what","where","when","why","whom","were","and","is","are","was","in","its","has","to","an","as","a","the","this","that","than","by","also","but","for","of","(",")","on","at","be","it","with"] : nil
	    	#cw = exclude_commom_words ? 'who|what|where' : nil

	    	# regexp removes words within words
	    	if false && exclude_commom_words
	    		# Regexp.escape(
	    		regexp_words = Regexp.new(cw.join("|")+"\i")
	    		#.gsub('to|an|a|the', '') 
				title = title.gsub(regexp_words, '')
			end
	    	#title = title.gsub(ClassifyItem::SANITIZE_REGEXP, '')
	    	#words = title.scan(/[\w'-]+|[[:punct:]]+/)
			words = title.split(/[\s,'-]+|[[:punct:]]+/)

			extra_words = []
			prev_word = nil

			words.each do |word|
				if word.last(2) == "'s"

					#kind of a hack to include basic names
					# so Joe Biden's campaign would become
					# ["Joe", "Biden's", "Joe", "Biden", "campaign"]
					unless prev_word.nil?
						extra_words.push prev_word
					end
					extra_words.push word.first(word.length-2)
				end
				prev_word = word
			end
			
			words.map!(&:downcase)
			words.delete(".")

=begin
			words.delete(",")
			
			words.delete("-")
			words.delete("?")
			words.delete("/")
			words.delete("\\")
			words.delete("()")
=end
			if exclude_commom_words
				cw = ["who","what","where","when","why","whom","were","and","is","are","was","in","its","has","to","an","as","a","the","this","that","than","by","also","but","for","of","(",")","on","at","be","it","with"]
				cw.each do |w|
					words.delete(w)
				end
				
				#_words = words
				#_words.each do |word|
				#	if !Stopwords.valid?(word)
				#		words.delete(word)
				#	end
				#end
			end

			return words + extra_words
		end
    end

    # parse title + description into words (words))
    # check word pairs and three words, calls SCORE_MATCHES
    # add to item_hash and item_suggestions
    # suggestions are FIRST MATCH of word ordered by FAME
    # loop unique words (without common words),
    # calls SCORE_MATCHES 

    # SCORE_MATCHES
    # search for items, or lookup items by word
	# calls contextual_matches: WHICH DOES...
		# parses (title + description) into words (or uses :target_words)
	    # gets score based on density
	    # TODO: get seperate score for ITEM and DESCRIPTORS
	    # loops through :new_items, gets descriptor names
	    # parses wd_descr and wiki_text and desriptor names into WORDS
	    # adds :score (density) and :hits
	    # returns {:matches=>(items indexed by key and ordered by density)}
    def self.get_tag_suggestions title,options={} 
    	
    	# options.reverse_update(age: 27, weight: 160, city: "New York")

    	result = {:tags_scored=>{},:matches=>{},:feedback=>[],:timers=>Summary.init_tagger_timer,:item_hash=>{},:item_suggestions=>[],:current_items=>[],:log=>[]}

    	title = title.nil? ? "" : title

    	description = options[:description] || nil
    	result[:log].push description

    	result[:current_items] = options[:current_items] || []
    	exclude_common_words = options[:exclude_common_words] || false
    	build_tags = options[:build_tags] || false
    	with_scores = options[:with_scores] || false
    	logger = options[:logger] || nil
    	refresh_cache = options[:refresh_cache] || false
    	cache_expiration = options[:cache_expiration] || 600000
    	
    	quick_mode = options[:quick] || false

    	#current_items,exclude_common_words=false, build_tags = false, with_scores = false, logger = nil
    	
    	lookup_options = {:refresh_cache=>refresh_cache,:cache_expiration=>cache_expiration}

    	logger.debug "INSIDE get_tag_suggestions" unless logger.nil?
    	logger.debug "with_scores: #{with_scores}" unless logger.nil?

    	logger.debug "text: #{title}" unless logger.nil?

    	result[:log].push "---TITLE"
    	result[:log].push title
    	result[:log].push "---TITLE END"

    	match_options = {:new_items=>[],:title=>title,:description=>description,:exclude_common_words=>true,:target_words=>[],:cache_expiration=>cache_expiration,:refresh_cache=>refresh_cache,:logger=>logger}
    	
    	# used in score_matches (combines title + description)
		snippet_words = match_options[:title]
		unless match_options[:description].nil?
			snippet_words+=(" " + match_options[:description])
		end

    	# for word pairs and word tuples, we want to consider common words
    	# removes punctuation, removes 's and removes common words like who, what, where, etc...
    	words = Summary.parse_into_words(snippet_words,exclude_common_words)
		
		target_words = exclude_common_words == true ? words : nil
		result[:log].push "TARGET_WORDS: #{target_words.to_s}"
		
		item_suggestions = []
		
		#title = title + ((description.nil?) ? "" : " #{description}")

		result[:log].push "----SNIPPET_words END"
		match_options[:target_words] = target_words
		match_options[:title_words] = match_options[:title].split(/[\s,'-]+|[[:punct:]]+/).reject { |i| i.blank? }
		match_options[:description_words] = match_options[:description].split(/[\s,'-]+|[[:punct:]]+/).reject { |i| i.blank? }

		match_options[:snippet_words] = match_options[:title_words] + match_options[:description_words] #snippet_words.split(/[\s,'-]+|[[:punct:]]+/).reject { |i| i.blank? } #Summary.parse_into_words match_options[:title], true
		

		result[:log].push match_options[:snippet_words]
		result[:log].push "----SNIPPET_words END LEN [#{match_options[:snippet_words].length}]"

		# loop through ALL WORDS (minus common words and stopwords)
		# score matches




=begin		
		st = Time.now
		words.uniq.each do |word|
			
			result[:log].push "words.uniq.each: #{word}"
			#match_options = {:new_items=>[],:title=>title,:description=>description,:exclude_common_words=>true,:target_words=>target_words,:cache_expiration=>cache_expiration,:refresh_cache=>false,:logger=>logger}
			
			#TODO: maybe update match_options[:new_items]
			result = Summary.score_matches word, match_options, result, lookup_options

		end
		result[:timers]["words.uniq.each"] = (Time.now-st)
		result[:timers]["words_uniq_each"] =(Time.now-st)
=end

		st = Time.now
		if quick_mode
			word_groups = words.uniq #+Summary.word_ngrams_grouped(words, [2,3])
		else
			word_groups = words.uniq+Summary.word_ngrams_grouped(words, [2,3])
		end

		word_groups.uniq.each do |word_pair|
			_st = Time.now
			_item_match = Item.cached_obj_by_name word_pair, 20, lookup_options[:refresh_cache],lookup_options[:cache_expiration]
			result[:timers]["cached_obj_by_name1"]+=(Time.now-_st)
			# TODO: get MORE THAN 1 item based on exact match, pass them in as candidates
			unless _item_match.nil? #|| result[:current_items].include?(_item_match.id)
				
				result[:item_hash][_item_match.id] = _item_match.name unless _item_match.nil?
				result[:log].push "word_pair: #{word_pair} suggestion: #{_item_match.name}" unless _item_match.nil?
				
				_sm = Time.now
				
				result = Summary.score_matches word_pair, match_options, result, lookup_options
				result[:timers]["score_matches_word_pair"]+=(Time.now-_sm)
=begin				
				begin
					
				rescue => err
				    result[:feedback].push "score_matches ERROR:"
				    result[:feedback].push "score_matches ERROR: #{word_pair} #{err}"
				     #raise 'likely one of the database fields is not found' 
				ensure
					#always run
				end
=end
				
			else
				#result[:feedback].push 
			end
		end

		result[:timers]["word_groups_each"] = (Time.now-st)


		#result[:timers]["words_uniq_each_cached_objs"] = result[:timers]["words_uniq_each_cached_objs"].to_s

		most_tagged_count = SourceTopic.most_tagged_count

		#TODO: CLEAR AND BOOST
			# CLEAR items that have low scores
		result[:tags_scored] = result[:tags_scored].reject { |k,tag| tag[:score_adj] < 0.0 }
		result[:tags_scored] = result[:tags_scored].sort_by{ |k, v| v[:score_adj] }.reverse.to_h
			# BOOST items that are commonly used as tags
		result[:tags_scored].each_pair do |k,v|
			tagged_count = SourceTopic.item_tagged_source_count k
			boost_score = 100*(tagged_count/((0.1*most_tagged_count)+tagged_count))
			result[:tags_scored][k][:boost_score] = boost_score
		end
		

		#result = {:feedback=>feedback,:timers=>timers}

		if build_tags
			new_items = Summary.bind_tags result[:item_suggestions], nil, false, result[:item_hash], 1200
			if with_scores
				#result[:tags_scored] = result[:tags_scored].sort_by{ |k, v| (v[:score] > v[:score_adj] ? v[:score] : v[:score_adj]) }.reverse.to_h
				
				result[:tags] = result[:tags_scored] #matches
				 #Summary.bind_tag_scores(new_items,matches)
			else
				result[:tags] = new_items
			end
		else
			if with_scores
				result[:tags] = result[:tags_scored] #matches
				#Summary.bind_tag_scores(new_items,matches)
			else
				result[:tags] = item_suggestions
			end
		end

		return result
    end
=begin
    def self.bind_tag_scores(new_items,matches)
    	matches = matches.sort_by{|k,v| v[:score]}.reverse
    	items = []
    	matches.each do |match|
    		items.push({:item=>})

    	end
    	
    	return {:items=>new_items, :scores=>matches}
    end
=end

	# search for items, or lookup items by word
	# calls contextual_matches: WHICH DOES...
		# parses (title + description) into words (or uses :target_words)
	    # gets score based on density
	    # TODO: get seperate score for ITEM and DESCRIPTORS
	    # loops through :new_items, gets descriptor names
	    # parses wd_descr and wiki_text and desriptor names into WORDS
	    # adds :score (density) and :hits
	    # returns {:matches=>(items indexed by key and ordered by density)}
	# returns result, with :tags_scored][key] = {:item=>__,:score_adj}  and :matches][key] = {:score=>__}
	def self.score_matches word, match_options, result={:tags_scored=>{},:feedback=>[],:timers=>{},:item_hash=>{}}, lookup_options={:refresh_cache=>false,:cache_expiration=>60000}
		
		result[:log].push "score_matches: #{word}"
		result[:timers]["words_uniq_each_cached_objs"] = 0 if !result[:timers].has_key?("words_uniq_each_cached_objs")
		#new_item1 = Item.get_item_by_name(word)
		#new_items = Item.get_items_by_name(word)
		_st = Time.now

#new_items = Item.cached_objs_by_name word, 20, lookup_options[:refresh_cache],lookup_options[:cache_expiration]
	
		refresh_search_cache = match_options[:refresh_cache]
		search_cache_expiration = 60000
		#sresult = Search.item_search2 word, pager, nil, match_options[:logger], word, use_search_cache, refresh_search_cache,nil,nil,true,search_cache_expiration #@use_cache, @update_cache (means refresh), filter_id=nil,descrip_ids=nil,admin_mode=false, cache_expiration = 600
		
		search_params = {:raw_title=>word,:pager=>{:page=>1,:page_size=>20},:use_cache=>true,:admin_mode=>true,:refresh_cache=>refresh_search_cache,:cache_expiration=>search_cache_expiration,:logger=>match_options[:logger]}

		sresult = Search.item_search2 word, search_params
		new_items = sresult[:items]
		result[:timers]["words_uniq_each_cached_objs"]+=(Time.now-_st)
		result[:log].push "-----NEW_ITEMS"
		result[:log].push "new_items: #{new_items.to_s}"
		
		result[:log].push "-----NEW_ITEMS END"

		_st = Time.now
		#match_options = {:new_items=>new_items,:title=>title,:description=>description,:exclude_common_words=>true,:target_words=>target_words,:cache_expiration=>cache_expiration,:refresh_cache=>false,:logger=>logger}
		match_options[:new_items] = new_items
		
		# uses :target_words (title + description)
	    # gets score based on density
	    # TODO: get seperate score for ITEM and DESCRIPTORS
	    # loops through :new_items, gets descriptor names
	    # parses wd_descr and wiki_text and desriptor names into WORDS
	    # adds :score (density) and :hits
		# returns {:item=>item_lookup[k],:score=>v,:words=>words_arr[k],:hits=>hits[k]}
		result = Summary.contextual_matches match_options, result
		
=begin
		_matches = context_obj[:matches]
		unless result[:matches].nil?
		result[:matches].each_pair do |mk,mv|

			if _matches.has_key?(mk) && !_matches[mk][:score].nil?
				if mv.has_key?(:score) && !mv[:score].nil? && (mv[:score] > _matches[mk][:score])
					result[:feedback].push "UPDATING SCORE FOR: #{mk}, #{result[:matches][mk][:score]} overrides #{_matches[mk][:score]}"
					_matches[mk][:score] = mv[:score]
				end
			else
				_matches[mk][:score] = mv[:score] if mv.has_key?(:score)
			end
			if _matches.has_key?(mk) && _matches[mk].has_key?(:score_adj) && !_matches[mk][:score_adj].nil?
				if mv.has_key?(:score_adj) && !mv[:score_adj].nil? && !_matches[mk][:score_adj].nil? && (mv[:score_adj] > _matches[mk][:score_adj])
					result[:feedback].push "UPDATING SCORE-ADJ FOR: #{mk}, #{result[:matches][mk][:score_adj]} overrides #{_matches[mk][:score_adj]}"
					_matches[mk][:score_adj] = mv[:score_adj]
				end
			else
				_matches[mk][:score_adj] = mv[:score_adj] if mv.has_key?(:score_adj)
			end
		end
		end
		result[:matches] = _matches

		#result[:matches] = context_obj[:matches]
		result[:feedback]+=context_obj[:feedback]

		result[:log]+=context_obj[:log]
		
		result[:timers]["context_density"]+=(context_obj[:timers]["context_density"])
		result[:timers]["context_parse"]+=(context_obj[:timers]["context_parse"])
		result[:timers]["context_descriptors"]+=(context_obj[:timers]["context_descriptors"])
		result[:timers]["words_uniq_each_context"]+=(Time.now-_st)
=end
		#matches.each_pair do |k,v|
		#	item_suggestions.push(k)
		#	item_hash[k] = v[:item].name #match.name
		#end

		result = Summary.evaluate_matches word, match_options, result 

		return result #{:timers=>timers,:matches=>matches,:feedback=>feedback, :item_hash=>item_hash}
	end

	# matches = {:item=>item_lookup[k],:score_adj=>0,:score=>v,:words=>words_arr[k],:hits=>hits[k]}
	def self.evaluate_matches word, match_options, result
		min_score = 0.01

		_st = Time.now
		unless result[:matches].nil? || (result[:matches].length ==0)
				result[:matches].each_pair do |key,value|
					unless value[:item].nil? #|| result[:current_items].include?(new_item1.id) || result[:item_suggestions].include?(new_item1.id)
						old_tags_scored = result[:tags_scored][key]
						old_score = {:score=>value[:score],:score_adj=>value[:score_adj],:hits=>value[:hits]}
						new_score = {:score=>0,:score_adj=>0,:hits=>0}

						if key == 198108
							result[:feedback].push "MM CHECK: #{word}"
							result[:feedback].push(old_score.to_json)
							result[:feedback].push "MM CHECK2: #{word}"
							result[:feedback].push(new_score.to_json)
							result[:feedback].push "MM CHECK3: #{word}"
							result[:feedback].push(old_tags_scored.to_json)
						end
						_as = Time.now
						adjuster = Summary.adjust_score match_options, value[:item], value[:score]
						result[:timers]["adjust_score"]+=(Time.now-_as)
						result[:timers]["adjust_score_hits"]+=1

						value[:score_adj] = adjuster[:score_adj]

						result[:item_suggestions].push(value[:item].id)
						result[:item_hash][value[:item].id] = value[:item].name
						result[:feedback].push "#{value[:item].name}, item: #{key} new_suggestion: #{value[:item].name} for #{word}"

						result[:log]+=adjuster[:feedback]

						if value[:score_adj] > min_score && value[:score] <= min_score
							value[:score] = min_score
						end

						new_score[:score] = value[:score]
						new_score[:score_adj] = value[:score_adj]
						new_score[:hits] = value[:hits]


						_new_score = value.merge(Summary.keep_best_score(new_score, old_tags_scored, old_score))
						
						if key == 198108
							result[:feedback].push "MM CHECK4: #{word}"
							result[:feedback].push(old_score.to_json)
							result[:feedback].push "MM CHECK5: #{word}"
							result[:feedback].push(new_score.to_json)
							result[:feedback].push "MM CHECK6: #{word}"
							result[:feedback].push(_new_score.to_json)
							result[:feedback].push "MM CHECK7: #{word}"
							result[:feedback].push(old_tags_scored.to_json)
						end

						if !_new_score[:score].nil?
							result[:tags_scored][key] = _new_score
						end
					else
						#result[:feedback].push "NO ITEM: item_suggestions has #{word}" if !value[:item].nil? && result[:item_suggestions].include?(value[:item].id)
						result[:log].push "KEY: #{key} new_item1.nil?: #{word}" if value[:item].nil?
					end
				end
		else
			result[:feedback].push "matches_null: #{word}"
		end

		result[:timers]["matches_each_pair"]+=(Time.now-_st)

		return result
	end

	def self.keep_best_score new_score, old_score, old_tags_scored
		ots_valid = !old_score.nil? && old_score.has_key?(:score) && !old_score[:score].nil?
		if new_score[:score].nil? && ots_valid
			new_score[:score] = old_score[:score].to_f
		elsif ots_valid && (old_score[:score].to_f > new_score[:score].to_f)
			new_score[:score] = old_score[:score].to_f
		end

		ots_valid2 = !old_score.nil? && old_score.has_key?(:score_adj) && !old_score[:score_adj].nil?
		if new_score[:score_adj].nil? && ots_valid2
			new_score[:score_adj] = old_score[:score_adj].to_f
		elsif ots_valid2 && (old_score[:score_adj].to_f > new_score[:score_adj].to_f)
			new_score[:score_adj] = old_score[:score_adj].to_f
		end


		return new_score
	end


	# matches = {:item=>item_lookup[k],:score_adj=>0,:score=>v,:words=>words_arr[k],:hits=>hits[k]}
	def self.evaluate_matches_old word, match_options, result
		min_score = 0.01

		_st = Time.now
		unless result[:matches].nil? || (result[:matches].length ==0)
				result[:matches].each_pair do |key,value|
					unless value[:item].nil? #|| result[:current_items].include?(new_item1.id) || result[:item_suggestions].include?(new_item1.id)
						#old_score = {:score=>value[:score],:score_adj=>value[:score_adj],:hits=>value[:hits]}
						new_score = {:score=>0,:score_adj=>0,:hits=>0}

						#old_score = result[:matches][key].has_key?(:score) ? result[:matches][key][:score] : nil
						old_score = (result[:tags_scored].has_key?(key) && !(result[:tags_scored][key][:score].nil?)) ? result[:tags_scored][key][:score] : 0.0
						old_score_adj = (result[:tags_scored].has_key?(key) && !(result[:tags_scored][key][:score_adj].nil?)) ? result[:tags_scored][key][:score_adj] : -5.0
						if old_score > value[:score]
							value[:score] = old_score
						end
						result[:feedback].push "#{value[:item].name} old score: #{old_score}, #{value[:score]}, adj: #{old_score_adj}"

						result[:item_suggestions].push(value[:item].id)
						result[:item_hash][value[:item].id] = value[:item].name
						result[:feedback].push "#{value[:item].name}, item: #{key} new_suggestion: #{value[:item].name} for #{word}"

						_as = Time.now
						adjuster = Summary.adjust_score match_options, value[:item], value[:score]
						result[:timers]["adjust_score"]+=(Time.now-_as)
						result[:timers]["adjust_score_hits"]+=1
						value[:score_adj] = (old_score_adj > adjuster[:score_adj]) ? old_score_adj : adjuster[:score_adj]
						
						result[:log]+=adjuster[:feedback]

						
						if result[:tags_scored].has_key?(key) && result[:tags_scored][key].has_key?(:score)
							_old_score = result[:tags_scored][key][:score]
							if old_score.nil? || _old_score > old_score
								old_score = _old_score
							end
						end
						result[:feedback].push "#{value[:item].name} old score 2: #{old_score}, #{value[:score]}"
						if value[:score_adj] > min_score && value[:score] <= min_score
							
							if !old_score.nil? && (old_score > min_score)
								value[:score] = old_score if (old_score > value[:score])
							else
								result[:matches][key][:score] = min_score
							end
						else
							if !old_score.nil? && (old_score > value[:score])
								value[:score] = old_score
							end

						end

						if !old_score.nil? && (old_score > value[:score])
							value[:score] = old_score
							result[:feedback].push "#{value[:item].name} old score setting: #{value[:score]}, #{value[:score_adj]}"
						end

						if value[:score_adj] < value[:score]
							#value[:score_adj] = value[:score]
						else
							#result[:matches][key][:score] = value[:score_adj]

						end

						# value = {:score=>,:item
						if false && result[:tags_scored].has_key?(key)
							if result[:tags_scored][key][:score] < value[:score]
								result[:tags_scored][key] = value
							else
								#result[:tag_scored][key][:score_adj] = value[:score_adj]
								#result[:tags_scored][key][:item] = value[:item]
								result[:feedback].push("SKIPPING SCORE UPDATE for #{key}")
							end
						else
							result[:tags_scored][key] = value
							result[:feedback].push "#{value[:item].name} old score tags_scored setting: #{value[:score]}, #{value[:score_adj]}, adj: #{old_score_adj}"
						end
						result[:feedback].push "item: #{key} score_adj: #{value[:score_adj]}, #{value[:score]}"
					else
						result[:feedback].push "item_suggestions has #{word}" if !value[:item].nil? && result[:item_suggestions].include?(value[:item].id)
						result[:log].push "new_item1.nil?: #{word}" if value[:item].nil?
					end
				end
		else
			result[:feedback].push "matches_null: #{word}"
		end

		result[:timers]["matches_each_pair"]+=(Time.now-_st)

		return result
	end

	def self.init_tagger_timer

		timer = {}
		timer["cached_obj_by_name1"] = 0
		timer["cached_obj_by_name2"] = 0
		timer["score_matches_word_pair"] = 0

		timer["words_uniq_each_cached_objs"] = 0
		timer["words_uniq_each_context"] = 0
		timer["matches_each_pair"] = 0
		timer["context_density"] = 0
		timer["context_parse"] = 0
		timer["context_descriptors"] = 0
		timer["adjust_score"] = 0
		timer["adjust_score_hits"] = 0

		return timer
	end

    def self.tag_suggest news_item, current_user, add_links, refresh_cache=false,logger = nil

		current_items = SummaryItem.where("summary_id = ?",news_item.id).pluck(:item_id)
		
		exclude_common_words = true

    	tag_options = {:exclude_common_words=>true,:current_items=>current_items,:refresh_cache=>refresh_cache,:logger=>logger}
		item_suggestions = Summary.get_tag_suggestions(news_item.title,tag_options)

		logger.debug("suggestions: " + item_suggestions.to_s) unless logger.nil?
		#new_tags = []
		
		summary_item_ids = news_item.item_ids

		new_items = Summary.bind_tags item_suggestions. summary_item_ids,true,nil,1200

		return new_items
    end


    # returns a list of ITEMS
    # optionally saves SummaryItem (or tags)
    def self.bind_tags item_suggestions, summary_item_ids, save_tags = true, item_hash = {}, cache_expiration=600000

    	new_items = [] #convert summary_item obj to items

    	if save_tags
			item_suggestions.each do |new_tag_id|
				if !summary_item_ids.include?(new_tag_id)
					si = SummaryItem.new(:summary_id=>news_item.id,:item_id=>new_tag_id,:createdby=>current_user.id,:score=>0.5)
			  		if si.save
			  			_name = nil
			  			if item_hash.nil? || !item_hash.has_key?(new_tag_id)
			  				_item = Item.cached_obj new_tag_id, false,false, cache_expiration
			  				_name = _item.nil? ? nil : _item.name
			  			else
			  				_name = item_hash[new_tag_id]
			  			end
			  			unless _name.nil?
				  			ni = Item.new(:name=>_name)
							ni.id = si.item_id
							new_items.push ni
				  			#new_tags.push si
			  			end
			  		end
		  		end
			end
		else
			new_items = Item.by_ids item_suggestions, true
		end

		return new_items
    end

    #  uses :target_words, which is the title and description
    # gets score based on density
    # TODO: get seperate score for ITEM and DESCRIPTORS
    # loops through :new_items, gets descriptor names
    # parses wd_descr and wiki_text and desriptor names into WORDS
    # adds :score (density) and :hits
    # returns {:matches=>(items indexed by key and ordered by density)}
    def self.contextual_matches options, result
    	feedback = []
    	log = []

    	#timers = {}
    	result[:timers]["context_density"] = 0 unless result[:timers].has_key?("context_density")
    	result[:timers]["context_parse"] = 0 unless result[:timers].has_key?("context_parse")
    	result[:timers]["context_descriptors"] = 0 unless result[:timers].has_key?("context_descriptors")

    	new_items = options[:new_items] || []
    	title = options[:title] || ""
    	description = options[:description] || nil
    	target_words = options[:target_words] || nil
    	exclude_common_words = options[:exclude_common_words] || false
    	logger = options[:logger] || nil
    	refresh_cache = options[:refresh_cache] || false
    	cache_expiration = options[:cache_expiration] || 600

    	#TODO: imagine two words with several synonyms
    	#      get the types, and if some have similar types, then assume those tags are true

    	text_arrs = {}
    	words_arr = {}
    	item_lookup = {}
    	
    	#title = title + ((description.nil?) ? "" : (" " + description))
    	
    	#if target_words.nil?
    	#	feedback.push "contextual_matches PARSE_INTO_WORDS"
    	#	target_words = Summary.parse_into_words(title,exclude_common_words)
    	#end
    	log.push "TARGET_WORDS_LENGTH: #{target_words.length}"
    	#feedback.push "TARGET_WORDS:: #{target_words.to_s}"
    	scores = {}
    	hits = {}

    	# loop through new_items, 
    	new_items.each do |item|
    		log.push "contextual_matches, CHECKING #{item.id}: #{item.name}"
    		#get words and phrases from wiki_text and descriptions, 
    		unless item.ambiguous == true

    			details_text = item.wd_descr.nil? ? "" : item.wd_descr
    			details_text+=(item.wiki_text.nil? ? "" : " #{item.wiki_text}")

    			_st = Time.now
    			#descriptors = Summary.item_descriptors(item.id,cache_expiration)
    			descriptors = Cache.get_item_descriptors_either_by_item_id item.id,false,cache_expiration, logger
    			result[:timers]["context_descriptors"]+=(Time.now-_st)

    			_st = Time.now
    			_words = Summary.parse_into_words(details_text,exclude_common_words)
    			
    			#this line is experimental
    			_words = _words.join(" ").split(/[\s,'-]+|[[:punct:]]+/).reject { |i| i.blank? }

    			words = _words + descriptors
    			result[:timers]["context_parse"]+=(Time.now-_st)

    			words_arr[item.id] = words

    			_st = Time.now
    			# returns (hits.to_f/attempts)
    			density_obj = Summary.density(target_words,words) #{:words=>words,:score=>0.0}
    			text_arrs[item.id] = density_obj[:density]

    			item_lookup[item.id] = item
    			result[:timers]["context_density"]+=(Time.now-_st)
    			
    			#text_arrs[item.id][:score] = Summary.density(target_words,words)
    			scores[item.id] = text_arrs[item.id]#[:score]
    			hits[item.id] = density_obj[:hits]

    			feedback.push "#{item.name}: score #{item.id} [#{scores[item.id]}] HITS: #{hits[item.id]}, density: #{text_arrs[item.id]}"
    			log.push "#{item.name} words: #{target_words.length}"
    			
    			#logger.debug "score for #{item.id}, #{item.name}" unless logger.nil?
    			#logger.debug text_arrs[item.id][:score]
    		else
    			feedback.push "ITEM IS AMBIGUOUS: #{item.name}"
    			#logger.debug "ITEM IS AMBIGUOUS: #{item.name}" unless logger.nil?
    		end
    	end
    	log.push "SCORES LENGTH: #{scores.length}"
    	#logger.debug "SCORES LENGTH: #{scores.length}" unless logger.nil?
    	#logger.debug scores.inspect unless logger.nil?
    	scores = scores.sort_by{ |k, v| v }.reverse.to_h
    	
    	results = {}
    	scores.each_pair do |k,v|
    		results[k] = {:item=>item_lookup[k],:score_adj=>0,:score=>v,:words=>words_arr[k],:hits=>hits[k]}
    	end
    	# compare match %, rank items and return one or more matches 
    	# (ideally one, or none)

    	result[:feedback]+=feedback
    	result[:log]+=log

    	#TODO: merge matches
    	result[:matches] = results

    	#return {:matches=>results,:feedback=>feedback,:log=>log,:timers=>timers} #text_arrs
    	return result
    end

    # pull in keywords from descriptors (item names)
    def self.item_descriptors item_id, cache_expiration = 6000, refresh=false, logger = nil

    	words = []
    	# Describe.where("item_id = ? OR item2_id = ?",item_id,item_id)
    	describes = Describe.relevant_by_id item_id, refresh, 2000, 0, cache_expiration, logger
    	describes.each do |describe|
    		if describe.item_id == item_id
    			#i2 = Item.where("id = ?",describe.item2_id).first
    			i2 = Item.cached_obj describe.item2_id, false,false, cache_expiration
    			words.push(i2.name) unless (i2.nil? || i2.name.nil?)
    		else
    			#i1 = Item.where("id = ?",describe.item_id).first
    			i1 = Item.cached_obj describe.item_id, false,false, cache_expiration
				words.push(i1.name) unless(i1.nil? || i1.name.nil?)
    		end
    	end

    	return words.uniq
    end


    # to match = item.name + synonyms
    # get the density of matches within the title + description
    def self.adjust_score match_options, item, score
    	score_adj_multiplier = 10
    	feedback = []
    	score_adj = 1.0*item.fame*item.relevance*score # *item.fame
		if item.wiki_text.nil?
			score_adj = score_adj*score_adj_multiplier
		end

		item_names = [item.name]+item.synonyms(true)
		# get the density of matches within the title + description
		
		phrases = {
			:all=>{:words=>match_options[:snippet_words],:weight=>1},
			:title=>{:words=>match_options[:title_words],:weight=>2},
			:description=>{:words=>match_options[:description_words],:weight=>0.75}
		}

		_density = Summary.names_density phrases, item_names, item

		feedback+=_density[:feedback]
		if _density[:hits] > 0 
			score_adj+=(5.0*_density[:hits])
		else
			score_adj-=1
		end
		feedback+=_density[:feedback]
		feedback.push "#{item.name}: score_adj #{score_adj}, #{_density[:hits]}, ID: #{item.id}"
		 # _density[:density]

		return {:score_adj=>score_adj,:feedback=>feedback}
    end

    # title_words = title + description, as an array
    def self.names_density phrases, item_names, item
		
		#TODO: if the description matches, and the title is a partial match, grant the title weight
		
		title_words = phrases[:all][:words]

		total_density = 0
		total_hits = 0
		total_attempts = 0
		feedback = []
		item_names.each do |name|
			name_words = name.split(" ") #all_names.split(" ") #item.name.split(" ")
			if name_words.length > 2
										# (target_words,words,single_words=true,word_pairs=false,ngram3=false,item_id=nil)
				_density = Summary.density(title_words,name_words,false,false,true,item.id)
			elsif name_words.length == 2
				_density = Summary.density(title_words,name_words,false,true,true,item.id)
			else
				_density = Summary.density(title_words,name_words,true,false,false,item.id)
			end
			total_hits+=_density[:hits]
			total_density+=_density[:density]
			total_attempts+=_density[:attempts]
			feedback+=_density[:feedback]
		end
		return {:density=>total_density,:hits=>total_hits,:attempts=>total_attempts,:feedback=>feedback}
    end

    # returns :density, hits and feedback
    # density can be low for items with MANY descriptors
    def self.density(target_words,words,single_words=true,word_pairs=false,ngram3=false,item_id=nil)
    	
    	hits = 0
    	attempts = 0
    	feedback = []

    	_words = {}
    	words.each do |w|
    		_words[w.downcase] = true
    	end

    	word_pair_multiplier = 1

    	if single_words
	    	target_words.each do |tw|
	    		tw = tw.downcase
	    		if Stopwords.valid?(tw) #!Stopwords.is?(tw) #true || Stopwords.valid?(tw) #ignored because Ireland was being flagged as a stopword (I wonder what other words)
		    		attempts+=_words.length
		    		if _words.has_key?(tw)
		    			hits+=1
		    		end
		    		#words.each do |w|
		    		#	attempts+=1
		    		#	if tw == w.downcase
		    		#		hits+=1
		    		#	end
		    		#end
	    		end
	    	end
    	end

    	use_indexed_pairs = true
    	if word_pairs
	    	# word pairs
	    	hits_obj = Summary.word_hits target_words, words, 2, use_indexed_pairs, word_pair_multiplier #NOT INDEXED
	    	attempts+=hits_obj[:hits]
	    	hits+=hits_obj[:hits]
    	end

    	if ngram3
	    	hits_obj = Summary.word_hits target_words, words, 3, use_indexed_pairs, word_pair_multiplier #NOT INDEXED
	    	attempts+=hits_obj[:hits]
	    	hits+=hits_obj[:hits]
    	end

    	return {:density=>(attempts == 0) ? 0.0 : (hits.to_f/attempts)*100,:hits=>hits,:attempts=>attempts,:feedback=>feedback}
    end

    def self.word_hits target_words, words, ngram_size=2, indexed = false, word_pair_multiplier = 1

    	hits = 0
    	attempts = 0

    	if indexed
	    	_targets = Summary.word_ngrams target_words, ngram_size, true
	    	_words = Summary.word_ngrams words, ngram_size, true

	    	_targets.each_pair do |tw,val|
	    		attempts+=_words.length
	    		if _words.has_key?(tw.downcase)
	    			hits+=(1*word_pair_multiplier)
	    		end
	    	end
	    else
	    	_targets = Summary.word_ngrams target_words, ngram_size
	    	_words = Summary.word_ngrams words, ngram_size

	    	_targets.each do |tw|
	    		_words.each do |w|
	    			attempts+=1
	    			if tw.downcase == w.downcase
	    				hits+=(1*word_pair_multiplier)
	    				#logger.debug "#{tw} == #{w}"
	    			end
	    		end
	    	end

	    end

    	return {:hits=>hits,:attempts=>attempts}
    end

    # returns 2 and 3 word pairs
    def self.word_ngrams_grouped words, ngrams=[2,3,4]
    	word_groups = []
    	word_pos = 0

    	join_by = " " #{}"_" # " "

    	ngram2 = ngrams.include? 2
    	ngram3 = ngrams.include? 3
    	ngram4 = ngrams.include? 4
    	words.each do |word|
			unless !ngram2 || (word_pos >= (words.length-1))
				word_pair = word + join_by + words[word_pos+1]
				word_groups.push word_pair
			end
			unless !ngram3 || (word_pos >= (words.length-2))
				word_pair = word + join_by + words[word_pos+1] + join_by + words[word_pos+2]
				word_groups.push word_pair
			end			
			unless !ngram4 || (word_pos >= (words.length-3))
				word_pair = word + join_by + words[word_pos+1] + join_by + words[word_pos+2] + join_by + words[word_pos+3]
				word_groups.push word_pair
			end
			word_pos+=1
		end
		return word_groups
    end

    def self.grouped_by_item_id item_id, limit = 20, refresh=false
		rkey = "summaries_grouped_l:#{limit}_#{item_id}"
		_topics = Cache.get_obj rkey, logger
		if _topics.nil? || refresh
			_topics = Summary.select("items.name,summaries.id,summaries.title,summaries.item_id,summaries.date,summaries.source_chars,orgs.id as org_id,orgs.name as source_name,sources.id as source_id, sources.title as source_title")
	  		.joins("LEFT JOIN items ON items.id = summaries.item_id")
	  		.joins("LEFT JOIN summary_items ON summary_items.summary_id = summaries.id")
	  		.joins("LEFT JOIN summary_sources ON summary_sources.summary_id = summaries.id")
			.joins("LEFT JOIN sources ON sources.id = summary_sources.source_id")
			.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			.where("(summaries.item_id = ? OR summary_items.item_id = ?)",item_id,item_id)
			.order("date DESC")
			.group("items.name,summaries.id,summaries.title,summaries.item_id,summaries.date,summaries.source_chars,orgs.id,orgs.name,sources.id,sources.title")
			.limit(limit)

			Cache.set_obj rkey, _topics.to_a, logger
		end
		return _topics
    end

=begin
    def self.topics source_id
		items = SourceTopic.select("items.id,items.name,items.wd_descr,items.wiki_text,source_topics.createdby,items.fame,items.relevance,source_topics.score,source_topics.approved")
		.joins("LEFT JOIN items ON source_topics.item_id = items.id")
		.where("source_topics.source_id = ?",source_id)
		return items
	end

	def self.cached_topics source_id, refresh=false,cache_expiration=60000
		return Cache.get_source_topics source_id, refresh, cache_expiration
	end
=end

	def topics limit=100, refresh=false, indexed=false
		logger.debug "inside summary.rb topics: #{self.id}"
		rkey = "summary_topics_l:#{limit}_#{self.id}"
  		_topics = Cache.get_obj rkey, logger
		if _topics.nil? || refresh
			logger.debug "refreshing summary.rb topics"
			_topics = SummaryItem.items_by_summary(self.id,self.item_id)
			Cache.set_obj rkey, _topics.to_a, logger
		else
			logger.debug "NOT refreshing summary.rb topics"
		end
		if indexed
			_data = {}
			_topics.each do |t|
				_data[t.id] = {:item=>t,:score=>nil,:score_adj=>nil}
			end
			return _data
		else
			return _topics
		end
	end

    def self.word_ngrams words, ngram = 2, indexed = false

    	_word_pairs = {}

    	join_by = indexed ? "_" : " "
    	word_pairs = []
    	if ngram == 2
	    	word_pos = 0
	    	words.each do |word|
				unless word_pos >= (words.length-1)
					word_pair = word + join_by + words[word_pos+1]
					if indexed
						_word_pairs[word_pair.downcase] = true
					else
						word_pairs.push word_pair
					end
				end
				word_pos+=1
			end
		elsif ngram == 3
			word_pos = 0
	    	words.each do |word|
				unless word_pos >= (words.length-2)
					word_pair = word + join_by + words[word_pos+1] + join_by + words[word_pos+2]
					if indexed
						_word_pairs[word_pair.downcase] = true
					else
						word_pairs.push word_pair
					end
				end
				word_pos+=1
			end
		end

		return indexed ? _word_pairs : word_pairs
    end

end
end