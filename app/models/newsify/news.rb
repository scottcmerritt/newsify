module Newsify
class News < Newsify::BackgroundProcess
	#TODO: bring in QueryGlobal from Newsify project, or fullerton-beta

	def initialize(attributes={})
		super(attributes)
	end

	# summaries and their topics (must have topics)
	def self.summaries_tagged limit, offset
		Summary.select("summaries.*,sources.id as source_id,sources.published_at as source_published_at,sources.title as source_title,orgs.name as org_name")
    	.with_summary_items
    	.with_sources.with_orgs
    	.where("summaries.post_mc_guid IS NULL AND NOT summary_items.id is NULL AND NOT sources.id IS NULL")
    	.order("summaries.id DESC")
    	.limit(limit)
    	.offset(offset)
	end

	# summaries (they don't need to have topics)
	def self.summaries limit, offset = 0

		Summary.select("summaries.*,sources.id as source_id,sources.published_at as source_published_at,sources.title as source_title,sources.description,orgs.name as org_name,orgs.name as source_name")
    	.with_sources.with_orgs
    	.where("summaries.post_mc_guid IS NULL AND NOT sources.id IS NULL")
    	.order("summaries.id DESC")
    	.limit(limit)
    	.offset(offset)
	end

	def self.summaries_from_sources sources
		source_ids = sources.collect {|v| v.id }

		return Summary.select("summaries.*,sources.id as source_id,sources.published_at as source_published_at,sources.title as source_title,sources.description,orgs.name as org_name,orgs.name as source_name")
    	.with_sources.with_orgs
    	.where("sources.id IN (?)",source_ids)
    	.order("summaries.id DESC")
	end


	def self.summary_sel
		#{}"summaries.*,sources.id as source_id,sources.title as source_title,sources.published_at as source_published_at,orgs.name as org_name"
		"summaries.id,summaries.mc_guid,summaries.post_mc_guid,summaries.date,summaries.published_at,summaries.created_at,summaries.title,sources.id as source_id,sources.title as source_title,sources.published_at as source_published_at,orgs.name as org_name"
	end
	def self.summaries_published limit, offset, orderby_sql, published=true, within_hrs = nil

		if published
			wh_sql = "NOT summaries.post_mc_guid IS NULL AND NOT sources.id IS NULL"
		else
			wh_sql = "summaries.post_mc_guid IS NULL AND NOT sources.id IS NULL"
		end
		if within_hrs
			Summary.select(News.summary_sel)
	    	.with_sources.with_orgs
	    	.where("#{wh_sql} AND sources.published_at > ?",Time.now - within_hrs.hours)
	    	.order(orderby_sql)
	    	.limit(limit)
	    	.offset(offset)
		else
			Summary.select(News.summary_sel)
	    	.with_sources.with_orgs
	    	.where(wh_sql)
	    	.order(orderby_sql)
	    	.limit(limit)
	    	.offset(offset)
	    end

	end

	def self.summaries_published_count published=true, within_hrs = nil, offset_hrs=0,offset = 0

		if published
			wh_sql = "NOT summaries.post_mc_guid IS NULL AND NOT sources.id IS NULL"
		else
			wh_sql = "summaries.post_mc_guid IS NULL AND NOT sources.id IS NULL"
		end
		if within_hrs
			
			Summary.with_sources.with_orgs
	    	.where("#{wh_sql} AND sources.published_at > ?",Time.now - within_hrs.hours)
	    	.count
		else
			Summary.with_sources.with_orgs
	    	.where(wh_sql)
	    	.count
	    end

	end

	def self.word_cloud articles
		
		word_hits = {}
		word_hit_rate = {} #what % of articles these words occur

		delimiters = [',', ' ', "'"]

		article_count = 0
		articles.each do |a|
			
			title = a.attributes['title'] ? a.attributes['title'] : a.source_title

			unless title.nil?
				article_count+=1
				_words = title.split(Regexp.union(delimiters))

				#_words = title.split(' ').split(',')
				_a_words = []

				_words.each do |word|
					_word = word.downcase

					if word_hits.has_key?(_word)
						word_hits[_word]+=1
					else
						word_hits[_word] = 1
					end

					_a_words.push(_word) unless _a_words.include?(_word) 
				end

				_a_words.each do |_word|

					if !word_hit_rate.has_key?(_word)
						word_hit_rate[_word]=1 
					else
						word_hit_rate[_word]+=1
					end

				end

			end
		end

		word_hit_rate.each_pair do |k,v|
			word_hit_rate[k] = word_hit_rate[k].to_f/article_count
		end
		
		word_hit_rate = Hash[word_hit_rate.sort_by{|k, v| v}.reverse]
		word_hits = Hash[word_hits.sort_by{|k, v| v}.reverse]

		word_hits.delete_if { |key, value| value < 2 }

		#word_hit_rate = word_hit_rate.sort_by {|k,v| v}
		return {:word_hits=>word_hits,:word_hit_rate=>word_hit_rate}

	end

	def self.fetch_data user_id, options={},do_fetch=false,use_cache=true
		news_util = News.new
		return news_util.fetch_data user_id, options, do_fetch, use_cache
	end

	def fetch_data user_id, options={}, do_fetch=false, use_cache = true
		_est_item_count = options[:each_cat_limit] * options[:cat_limit]
		status_start _est_item_count, "Loading fetch data"

		results = nil
		st_total = Time.now

		ignored_items = Cache.get_ignored "news", true

		st = Time.new
		source_hash_string = {:user_id=>user_id,:options=>options.except(:logger,:refresh_cache)}.to_json.to_s
		hashkey = Digest::SHA256.hexdigest(source_hash_string)
		
		options[:logger].debug "REFRESH: #{options[:refresh_cache]}" unless options[:logger].nil?
		
		if (options[:refresh_cache]==false || options[:refresh_cache].blank?)
			options[:logger].debug "USE CACHE: #{options[:refresh_cache]}" unless options[:logger].nil?
		end
		if use_cache && (options[:refresh_cache]==false || options[:refresh_cache].blank?)
		    
		    options[:logger].debug "GOT CACHE:" unless options[:logger].nil?
		    results = Cache.get_obj hashkey, options[:logger]
		end


		unless results.nil?
			et = Time.new
			results[:timer][:use_cache] = (et-st).to_s
		else
			et = Time.new
			results = {:timer=>{},:categories=>[],:to_fetch=>[],:items_idx=>{},:fetch_items=>[],:to_summarize=>[],:feedback=>[],:fetched=>[]}
			results[:timer][:check_cache] = (et-st).to_s

			st = Time.new
			if options[:categories].nil?
				results[:categories] = Item.where("template = ? and hidden = 0",1)
				.limit(options[:cat_limit])
				.offset(options[:cat_offset])
			else
				results[:categories] = options[:categories]
			end
			et = Time.new
			results[:timer][:load_cats] = (et-st).to_s


			# get most popular items
			st = Time.new
			cat_items = QueryGlobal.top_items_full nil,options[:each_cat_limit],options[:offset]
			cat_items.each do |cat_item|
				unless results[:items_idx].has_key?(cat_item.id)
					results[:items_idx][cat_item.id] = cat_item
					results[:fetch_items].push(cat_item.id) unless ignored_items.has_key?(cat_item.id)
				end
			end
			et = Time.new
			results[:timer][:load_top_items] = (et-st).to_s

			# get items with most articles
			st = Time.new
			cat_items = Item.popular nil,options[:each_cat_limit],options[:offset],use_cache, options[:logger]
			cat_items.each do |cat_item|
				unless results[:items_idx].has_key?(cat_item.id)
					results[:items_idx][cat_item.id] = cat_item
					results[:fetch_items].push(cat_item.id) unless ignored_items.has_key?(cat_item.id)
				end
			end
			et = Time.new
			results[:timer][:load_popular] = (et-st).to_s

			# NOW we have a list of items (in :fetch_items AND :items_idx)

			st = Time.new
			results[:categories].each do |cat|
				cat_items = Item.popular cat.id,options[:each_cat_limit],options[:offset], use_cache, options[:logger]
				cat_items.each do |cat_item|
					unless results[:items_idx].has_key?(cat_item.id)
						results[:items_idx][cat_item.id] = cat_item
						results[:fetch_items].push(cat_item.id) unless ignored_items.has_key?(cat_item.id)
					end
				end
			end
			results[:timer][:add_cat_items] = (Time.new-st).to_s
			
			range_size = results[:fetch_items].length - options[:offset]
			if options[:limit] < range_size
				range_size = options[:limit]
			end
			#results[:to_fetch] = results[:fetch_items][options[:offset],range_size]

			results[:to_fetch] = results[:fetch_items] #[options[:offset],range_size]
		end

		status_item_count results[:to_fetch].length

		options[:logger].debug "updating status_item_count: #{results[:to_fetch].length}" unless options[:logger].nil?

		st = Time.now
		Cache.set_obj hashkey,results, options[:logger]
		et = Time.now
		results[:timer][:set_cache] = (et-st).to_s

		if do_fetch
			status_update "Fetching data"

			import_params = {}

			if options[:get_headlines]
				status_update "Fetching data (headlines)"
				search_result = Import.start_import import_params,user_id,options[:logger]
				results[:fetched].push({:title=>"Headlines",:item_id=>nil,:import_count=>search_result[:import_count]})
			end

			status_update "Fetching data (by keyword)"
			results[:to_fetch].each do |fi|
				status_incr 1

				options[:logger].debug "updating status_incr: #{results[:to_fetch].length}" unless options[:logger].nil?

				item = results[:items_idx][fi]
				import_params[:q] = item.name

			  	import_params[:item_id] = item.id
		      	#TODO: API upgrade is needed to get more than 1 page
			  	import_params[:max_pages] = 1 #3
			  	search_result = Import.start_import import_params,user_id,options[:logger]
				results[:fetched].push({:title=>"Item #{fi}",:item_id=>fi,:import_count=>search_result[:import_count]})
			end
		end

		# loop through items and get a random article (for now)
		# TODO: determine a better way to decide what article to summarize
		st = Time.new
		if options[:prep_for_summary]
			summarize_obj = News.to_summarize results[:to_fetch], options, results[:items_idx]
			results[:to_summarize] = summarize_obj[:to_summarize]
			results[:feedback]+=summarize_obj[:feedback]
		end
		et = Time.new
		results[:timer][:prep_for_summary] = (et-st).to_s

		et_total = Time.now
		results[:timer][:fetch_data] = (et_total-st_total).to_s

		return results
	end

	def self.to_summarize to_fetch, options, items_idx = {}

		results = {:feedback=>[],:to_summarize=>[]}

		#@fetch_items.each do |fi|
		to_fetch.each do |fi|
			if !items_idx.nil? && items_idx.has_key?(fi)
				results[:feedback].push "Fetch item: #{items_idx[fi].name}"
			else
				results[:feedback].push "Fetch item ID: #{fi}"
			end
			#within_hrs = 24
			#sample_size = 1

			# gets FETCHED article(s) based on a passed in topic
			sample_articles = Source.to_summarize fi, options[:within_hrs], options[:sample_size] #Source.recent_articles fi, options[:within_hrs], options[:sample_size]
			unless sample_articles.nil?
				new_article = sample_articles[0]
				results[:to_summarize].push(new_article) unless new_article.nil?
			end
		end

		return results
	end

	def self.get_remote_views_v2 url, get_params, site_id=0, use_ssl=true

		data = ApiData.make_get_req url,get_params,use_ssl

		return data

	end
	def self.get_remote_views url, get_params, site_id=0, use_ssl=true

		upvote_dates = nil
		time_spent = {} #by summary
		view_count = {}

		time_spent_by_item = {} #by item

		results = {}
		data = Community::ApiData.make_get_req url,get_params,use_ssl
		results[:counts] = {:posts_view_count=>data["my_count"],
					:posts_time_spent=>data["my_time"],
					:total_views=>data["total_views"],
					:total_time=>data["total_time"]
				}
		results[:mc_guids] = []
		data["views"].each do |view|
			if view['mc_guid']
				results[:mc_guids].push(view['mc_guid'])
				time_spent[view['mc_guid']] = 0 if !time_spent.has_key?(view['mc_guid'])
				time_spent[view['mc_guid']]+=view["uview_time"].to_f

				view_count[view['mc_guid']] = 0 if !view_count.has_key?(view['mc_guid'])
				view_count[view['mc_guid']]+=1
			end
		end

		results[:summaries] = []
		results[:item_hits] = {}
		results[:items] = {}
		all_summaries = Summary.get_by_post_mc_guids results[:mc_guids]
		all_summaries.each do |s|

			items = s.items
			items.each do |item|
				results[:items][item.item_id] = item
				if results[:item_hits].has_key?(item.item_id) 
					results[:item_hits][item.item_id]+=1
				else
					results[:item_hits][item.item_id] = 1
				end

				time_spent_by_item[item.item_id] = 0 if !time_spent_by_item.has_key?(item.item_id)
				time_spent_by_item[item.item_id]+=time_spent[s.post_mc_guid]

			end
			voted_at = upvote_dates.nil? ? nil : upvote_dates[s.post_mc_guid]
			results[:summaries].push(:summary=>s,:items=>items,:voted_at=>voted_at)
		end

		results[:item_hits] = Hash[results[:item_hits].sort_by{|k, v| v}.reverse]
		results[:views_by_post] = view_count
		results[:time_by_post] = time_spent
		results[:time_by_item] = time_spent_by_item
		return results
	end


	def self.get_remote_engagement url, get_params, site_id=0, use_ssl=true

		results = {}
		data = Community::ApiData.make_get_req url,get_params,use_ssl

		results[:counts] = {:posts_upvote_count=>data["posts"]["upvote_count"],
					:posts_spam_count=>data["posts"]["spam_count"]
				}
		results[:mc_guids] = []
		upvote_dates = {}
		data["posts"]["upvotes"].each do |upvote|
			unless upvote['mc_guid'].nil?
				results[:mc_guids].push(upvote['mc_guid'])
				upvote_dates[upvote['mc_guid']]=upvote['updated_at'] #created_at
			end
		end

		results[:summaries] = []
		results[:item_hits] = {}
		results[:items] = {}
		all_summaries = Summary.get_by_post_mc_guids results[:mc_guids]
		all_summaries.each do |s|

			items = s.items
			items.each do |item|
				results[:items][item.item_id] = item
				if results[:item_hits].has_key?(item.item_id) 
					results[:item_hits][item.item_id]+=1
				else
					results[:item_hits][item.item_id] = 1
				end
			end
			results[:summaries].push(:summary=>s,:items=>items,:voted_at=>upvote_dates[s.post_mc_guid])
		end

		results[:item_hits] = Hash[results[:item_hits].sort_by{|k, v| v}.reverse]
		results[:summaries] = results[:summaries].sort_by{|v| v[:voted_at]}.reverse

		#results[:summaries] = Hash[results[:summaries].sort_by{|k, v| v[:summary].published_at}.reverse]

		return results
	end

	def self.sel_sql
		"sources.id,sources.title,sources.description,sources.url,sources.id as source_id,sources.title as source_title,sources.description as source_description,sources.published_at,orgs.name as source_name"
	end
	def self.scores_sql
		"sources.is_spam,sources.spam_score,sources.is_clickbait,sources.clickbait_score,sources.is_ad,sources.ad_score,sources.is_product,sources.product_score,sources.is_foreign,sources.foreign_score"
	end
	def self.articles_summarized limit = 200, offset = 0
		return Source.select("#{sel_sql},#{scores_sql}")
		.with_summaries
		.with_orgs.with_content
		.by_published_date(true)
		.where("summaries.post_mc_guid IS NULL AND NOT summaries.id IS NULL")
		.limit(limit).offset(offset)
	end

	def self.article_snippets within_hrs, offset_hrs=0,limit=5000,format = nil, query = nil, category_id = nil
		scores_sql = News.scores_sql
		sel_sql = News.sel_sql

		if query.blank?
			if !category_id.nil?
				data = Source.by_category category_id, limit
				#data = Source.select("#{sel_sql},#{scores_sql}")
				#.with_orgs.with_content

			elsif offset_hrs.nil? || offset_hrs == 0
				data = Source.select("#{sel_sql},#{scores_sql}")
				.with_orgs.with_content
				.sortByPublished(true)
				.where("contents.id is NULL AND sources.published_at > ?",(Date.today - within_hrs.hour).to_datetime)
				.limit(limit)
			else
				data = Source.select("#{sel_sql},#{scores_sql}")
				.with_orgs.with_content
				.sortByPublished(true)
				.order("sources.published_at DESC")
				.where("contents.id is NULL AND sources.published_at > ? AND sources.published_at < ?",(Date.today - within_hrs.hour).to_datetime,(Date.today - offset_hrs.hour).to_datetime)
				.limit(limit)
			end
		else
			q_fmt = "%"+query.downcase+"%" 
			if offset_hrs.nil? || offset_hrs == 0
				data = Source.select("#{sel_sql},#{scores_sql}")
				.with_orgs.with_content
				.sortByPublished(true)
				.where("sources.published_at > ? AND (LOWER(sources.title) LIKE ? OR LOWER(sources.description) LIKE ? ) AND contents.id is NULL ",(Date.today - within_hrs.hour).to_datetime,q_fmt,q_fmt)
				.limit(limit)
			else
				data = Source.select("#{sel_sql},#{scores_sql}")
				.with_orgs.with_content
				.sortByPublished(true)
				.where("sources.published_at > ? AND sources.published_at < ? AND (LOWER(sources.title) LIKE ? OR LOWER(sources.description) LIKE ? ) AND contents.id is NULL",(Date.today - within_hrs.hour).to_datetime,(Date.today - offset_hrs.hour).to_datetime,q_fmt,q_fmt)
				.limit(limit)
			end
		end

		if format.nil?
			return data
		else
			return data.as_json
		end
	end

	def self.article_images query, limit=100, offset_hrs=0
		scores_sql = News.scores_sql
		data = []
		if query.is_a? Array
			q_fmts = query.map {|val| "%#{val.downcase}%" }
			#Product.where("name ILIKE ANY ( array[?] )", myarray_with_percetage_signs)
			
			data = Source.select("sources.id,sources.urlToImage as image_url,sources.title,sources.description,#{scores_sql}sources.url,sources.id as source_id,sources.title as source_title,sources.description as source_description,sources.published_at,orgs.name as source_name")
			.joins("LEFT JOIN contents ON contents.source_id = sources.id")
			.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			.order("sources.published_at DESC")
			.where("(LOWER(sources.title) LIKE ANY (array[?]) OR LOWER(sources.description) LIKE ANY (array[?])) AND contents.id is NULL ",q_fmts,q_fmts)
			.limit(limit)

		else
		q_fmt = "%"+query.downcase+"%" 

			data = Source.select("sources.id,sources.urlToImage as image_url,sources.title,sources.description,#{scores_sql}sources.url,sources.id as source_id,sources.title as source_title,sources.description as source_description,sources.published_at,orgs.name as source_name")
			.joins("LEFT JOIN contents ON contents.source_id = sources.id")
			.joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			.order("sources.published_at DESC")
			.where("(LOWER(sources.title) LIKE ? OR LOWER(sources.description) LIKE ? ) AND contents.id is NULL ",q_fmt,q_fmt)
			.limit(limit)
		end
		return data
	end

	# get posts viewed from remote site
	# return sources with less than [view_threshold] seconds per view
	def self.get_ignored_posts params={},view_threshold=2, excluded_mc_guids=[],logger = nil

		max_items = 5000

		data = News.get_remote_views params[:post_url], params[:remote_user_params], params[:site_id]

		mc_guids = []
		data[:summaries].each do |s|
			
			_views = data[:views_by_post][s[:summary].post_mc_guid]
			_time_spent = data[:time_by_post][s[:summary].post_mc_guid].to_f*60*60
			_per_view = _time_spent/_views

			if _per_view < view_threshold && mc_guids.length <= max_items
				if !s[:summary].post_mc_guid.nil? && !excluded_mc_guids.include?(s[:summary].post_mc_guid)
					mc_guids.push s[:summary].post_mc_guid
				end
			end
		end

		logger.debug "MC_GUIDS" unless logger.nil?
		logger.debug mc_guids unless logger.nil?

		return Source.by_summary_post_mc_guids mc_guids, false

	end

	# get posts viewed from remote site
	# return sources with less than [view_threshold] seconds per view
	def self.get_read_posts params={},view_threshold=2, excluded_mc_guids=[],logger = nil

		max_items = 5000

		data = News.get_remote_views params[:post_url], params[:remote_user_params], params[:site_id]

		mc_guids = []
		data[:summaries].each do |s|
			
			_views = data[:views_by_post][s[:summary].post_mc_guid]
			_time_spent = data[:time_by_post][s[:summary].post_mc_guid].to_f*60*60
			_per_view = _time_spent/_views

			if _per_view > view_threshold && mc_guids.length <= max_items
				if !s[:summary].post_mc_guid.nil? && !excluded_mc_guids.include?(s[:summary].post_mc_guid)
					mc_guids.push s[:summary].post_mc_guid
				end
			end
		end

		logger.debug "MC_GUIDS" unless logger.nil?
		logger.debug mc_guids unless logger.nil?

		return Source.by_summary_post_mc_guids mc_guids, false

	end

end
end