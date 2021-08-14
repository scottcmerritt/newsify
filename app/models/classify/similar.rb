module Classify
	class Similar < Newsify::BackgroundProcess
	require 'tf-idf-similarity'

		attr_reader :builder,:model,:corpus,:items_idx,:custom_timer,:rows,:to_classify,:to_summarize,:total_checks
		def initialize(attributes={})
			super(attributes)
			#@logger = attributes[:logger] || nil
			#@custom_timer = {}

			@within_hrs = attributes[:within_hrs] || 48
			@hrs_offset = attributes[:hrs_offset] || 0

			@to_classify = attributes[:to_classify] || []
			@to_summarize = []

			@query 				= attributes[:query] || nil
			@suggest_tags 		= attributes[:suggest_tags] || false
			@suggested_params 	= attributes[:suggested_params] || nil

			@model = nil
			@corpus = []

			@items_idx = {}	
			@total_checks = 0
			@pairs = {}
			@belongs_to = {} # the parent items that contain the item
			@skip_these = {}

			@hit_count = {}
			@best_match = {} # id => {:id=>__,:score=>__}
		
			@to_classify = []

			@score_threshold = 0.30
	  		@skip_threshold = 0.3
	  		@group_threshold = 0.4
	  		@skip_length = 3

	  		@show_all = attributes[:show_all] || false

	  		@builder = nil
	  		@rows = []
		end

		def self.group_similar! do_run=true,do_save=true,import_id=nil
			similar = Similar.new({})
	    	neww_group_ids = nil

		    grouped_ids = Newsify::Source.where("created_at > ? AND is_group = ?",7.days.ago,true).pluck(:id)
		    sources = Newsify::Source.where("((created_at > ? AND is_group = ?) OR id IN (?))",1.days.ago,false,grouped_ids)
		    
		    import_source_ids = Newsify::ImportSource.where(import_id:import_id).pluck(:source_id)
		    sources = sources.or(Newsify::Source.where(id: import_source_ids)) unless import_id.nil?

		    sources = sources.order("created_at DESC")

		    if do_run || do_run == "1"
			    similar.setup false, sources
			    similar.run
			    similar.group_similar
			    new_group_ids = similar.build_source_groups if do_save || do_save == "1"
			 end
			return similar, sources, new_group_ids
		end

		
		def suggest_tags?
			@suggest_tags
		end

		def summarize dry_run = false, summarize_api_id = 0
			status_update "Summarizing articles"
			@log.push "dry run: #{dry_run}"
			status_item_count @to_summarize.length
			status_update "Summarizing articles: #{@to_summarize.length} items"

			_result = Classify::Summarize.from_sources @to_summarize, summarize_api_id, @logger, dry_run
			return _result
		end

		def publish post_info
			status_update "Publishing articles: #{@to_summarize.length} items"
	  		@to_share = Newsify::News.summaries_from_sources @to_summarize
	  		#TODO: get summaries from to_summarize
	  		
	  		return Community::ApiData.share_summaries @to_share, post_info, @logger #,@use_ssl
		end

		def load_articles options #within_hrs=24,offset_hrs = 0, classify_limit = 100, use_suggested=false
			@within_hrs = options[:within_hrs] || @within_hrs
			@hrs_offset = options[:hrs_offset] || @hrs_offset

			classify_limit = options[:limit] || 100
			labeled = options[:labeled] || {}

			st = Time.now
			if !@suggested_params.nil? #labeled.has_key?(:use_suggested) && labeled[:use_suggested] == true			
				status_update "Grouping similar articles: using engagement data"
				lbl_name = labeled[:lbl_name] || "upvote"

				#@suggested_params[:get_read] = true
				@suggested_params[:limit] = classify_limit
				@suggested_params[:within_hrs] = @within_hrs
				@suggested_params[:query] = @query
				#@suggested_params[:use_description] = true

				@guess_interest = GuessInterest.new(@suggested_params)
				@guess_interest.run
				@to_classify = []

				@guess_interest.to_classify.each do |item|
					unless @guess_interest.guesser.nil?
						lbl = @guess_interest.guesser.item_guesses[item.id] ? @guess_interest.guesser.item_guesses[item.id][:label] : nil
						@to_classify.push item if lbl == lbl_name
					end
				end
				@custom_timer = @custom_timer.merge(@guess_interest.custom_timer)
			elsif @params[:category_id]
				@logger.debug "load by cat id: #{@params[:category_id]}"
				status_update "Grouping similar articles: using category ID"
				@to_classify =  Newsify::News.article_snippets @within_hrs, @hrs_offset, classify_limit, nil, @query, @params[:category_id]
			elsif @params[:use_summarized]
				status_update "Grouping similar articles: using summarized"
				@to_classify =  Newsify::News.articles_summarized classify_limit
			else
				status_update "Grouping similar articles: using recent news"
	  			@to_classify =  Newsify::News.article_snippets @within_hrs, @hrs_offset, classify_limit,nil,@query
	  		end
	  		
	  		et = Time.now

			@custom_timer["to_classify"] = (et-st).to_s 
		end

		def setup prep_text = false, to_classify = nil
			require 'unicode_utils'
			_items_idx = {}
			@to_classify = to_classify unless to_classify.nil?

			st = Time.new
			@to_classify.each do |s|
		  		_items_idx[s.id] = s
		  		text = s.title.nil? ? "[blank article, no title]" : s.title.downcase
		  		text+=(s.description.nil? ? "" : " " + s.description)
		  		text = Classify::Util.prepped(text) if prep_text
		  		tokens = UnicodeUtils.each_word(text).to_a - ['and', 'the', 'to']
		  		doc = TfIdfSimilarity::Document.new(text, :tokens => tokens)
		  		@corpus.push doc
	  		end

	  		@model = TfIdfSimilarity::TfIdfModel.new(@corpus, :library => :narray)
			et = Time.new
			@custom_timer["load_corpus"] = (et-st).to_s 
			st = Time.new
			@matrix = @model.similarity_matrix
			et = Time.new
			@custom_timer["load_matrix"] = (et-st).to_s 

			@items_idx = _items_idx
		end

		def run
			status_update "Grouping similar articles"
			st = Time.now
			@corpus.each_with_index do |doc1,i1|
				item_key = @to_classify[i1].id

				if @show_all
					@pairs[item_key] = {} if !@pairs.has_key?(item_key)
				end
				@hit_count[item_key] = 0 unless @hit_count.has_key?(item_key)

				if @skip_these.has_key?(item_key)

				else
					@corpus.each_with_index do |doc2,i2|
						item2_key = @to_classify[i2].id

						if !@pairs.has_key?(i2) || @pairs[i2].length < @skip_length

							@pairs[item_key] = {} if !@pairs.has_key?(item_key)
							

							if i1 != i2
								_score = @matrix[@model.document_index(doc1), @model.document_index(doc2)]
								
								@total_checks+=1
								if _score > @score_threshold
									
									@hit_count[i2] = 0 unless @hit_count.has_key?(i2)
									@hit_count[i2]+=1

									#@pairs[item_key].push({:score=>_score,:id=>@to_classify[i2].id})
									@pairs[item_key][item2_key] = {:score=>_score,:id=>item2_key}
								end
								if _score > @skip_threshold
									@skip_these[item2_key] = true
								end
								
							end
						end
					end

		#			@pairs[item_key] = @pairs[item_key].sort_by{|v| v[:score]}.reverse
					@pairs[item_key] = Hash[@pairs[item_key].sort_by{|k, v| v[:score]}.reverse]
					@pairs[item_key].each_pair do |k,pair|
						_score = pair[:score]
						if _score > @group_threshold
							@belongs_to[pair[:id]] = {} if !@belongs_to.has_key?(pair[:id])
							
							@belongs_to[pair[:id]][item_key] = {:id=>item_key,:grouped=>true}
							#skip_these[pair[:id]] = true #if _score > @skip_threshold
						end
					end
				end
			end

			et = Time.now
		  	@custom_timer["run_similarity_check"] = (et-st).to_s 
		end

		def group_similar
			@rows = []
			rendered = {}

			@builder = SimilarRows.new(:items_idx=>@items_idx)

			@pairs.each_pair do |k,v|
				if @show_all || !rendered.has_key?(k) && v.length > 0
					rendered[k] = true
					
					row = @builder.new_row k # @items_idx {:item=>@items_idx[k],:related=>nil,:pairs=>nil}

					pairs = []
					
					related = {}

					v.each_pair do |idx,result|
						if result[:id] != k
							rendered[result[:id]] = true
							pairs.push({:item=>@items_idx[result[:id]]})

							if @pairs.has_key?(result[:id])
								@pairs[result[:id]].each_pair do |k2,v2|
									related[result[:id]] = v2 unless @pairs[k].has_key?(result[:id])

								end
							end
							if @belongs_to.has_key?(result[:id])
								@belongs_to[result[:id]].each_pair do |bk,bv|
									related[bk] = bv unless bk == k || @pairs[k].has_key?(bk)
								end
							end
						end
					end
					_related = []
					related.each_pair do |rk,rv|
						rendered[rk] = true
						_related.push({:item=>items_idx[rk]})
					end
					row[:related] = _related
					row[:pairs] = pairs
					@builder.add_row row
					#@rows.push row
				end
			end

			@builder.sort_by_pair_count
			# here we have @rows available

			#_row_items = @builder.rows.collect { |v| v[:item] }
			
		end

		def build_to_summarize

			@to_summarize = []
			_all = {}

			@builder.rows.each do |row|
				item = row[:item]
				ignore_row = false

				row[:related].each do |_row|
					if _all.has_key?(_row[:item].id)
						ignore_row = true
					end
					_all[_row[:item].id]=true
				end
				if _all.has_key?(item.id)
					ignore_row = true
				end
				if ignore_row
					@log.push "IGNORING: #{item.id}"
				else
					@log.push "Adding: #{item.id}"
					@to_summarize.push item
				end
			end

		end

		def group_rows source, pairs, group_id
			#source.update_attributes(is_group: (group_id == source.id), group_id: group_id)
			source.update(is_group: (group_id == source.id), group_id: group_id)
			source_group = Newsify::SourceGroup.create(source_id:group_id,child_id:source.id) unless group_id == source.id

			if pairs.length > 0
				pairs.each do |pair|
					source2 = pair[:item]
					unless Newsify::SourceGroup.where(source_id:group_id,child_id:source2.id).exists?
						source_group = Newsify::SourceGroup.create(source_id:group_id,child_id:source2.id) unless group_id == source2.id
						#source2.update_attributes(is_group: (group_id == source2.id),group_id: group_id) # unless source2.is_group == true
						source2.update(is_group: (group_id == source2.id),group_id: group_id)
					end
				end
			else
				# NOT A GROUP

			end

		end

		# lookup so a second group is not created IF one already exists
		# in some cases where items A,B,C are similar and B,C,D are similar, this will create issues
		# the history will be stored in the SourceGroup table, but the group_id will be UPDATED
		# the idea of MULTIPLE usable groups, will be handled by items (via source_topics)
		def first_group pairs
		  	pairs.each do |pair|
		  		return pair[:item].id if pair[:item].is_group
		  	end
		  	nil
		end

		def build_source_groups
		  	new_groups = []
		  	self.builder.rows.each do |row|
		  		source = row[:item]

		  		first_group_id = self.first_group row[:pairs]
		  		group_id = first_group_id.nil? ? source.id : first_group_id
		  		new_groups.push group_id
		  		self.group_rows source, row[:pairs], group_id
		  	end
		  	new_groups
		end
	end

end