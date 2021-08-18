module Newsify
class Source < ActiveRecord::Base #AbstractModel #ActiveRecord::Base
	  self.table_name = 'sources'
	  is_impressionable if defined?(is_impressionable)
	  acts_as_commentable
	  acts_as_favoritable

	  def self.model_name
  		ActiveModel::Name.new("Newsify::Source", nil, "Source")
		end

	  include Newsify::GenericObj, Newsify::NewsClassify
	  include Community::IconUtil, Community::VoteCacheable
	  acts_as_votable
=begin	
	
	include GenericObj, IconUtil
	include NewsManager, NewsClassify
	include VoteCacheable
=end
	attribute :guess_score
	attribute :guess_reason


	has_many :source_authors
	has_many :source_topics
	has_many :source_topics_removed
	has_many :summary_sources
	has_many :import_sources
	has_many :source_opinions

	belongs_to :summary_source, optional: true
	belongs_to :user, optional: true #, :class_name => 'User', foreign_key: 'createdby'


	def guess_scope scope: "interesting"
		Community::GuessScope.select("*").where(target_type:"Newsify::Source",target_id:self.id,scope:scope).first
	end

	def grouped?
		!similar_sources.nil?
		#is_group && !similar_sources.nil?
	end
	
	# determines if the article has been classified, and the content scanned?
	# TODO: consider making this process more explicitly logged
	def classified?
		!source_topics.empty?
	end

	# EXAMPLE LEFT OUTER JOIN
	# https://guides.rubyonrails.org/active_record_querying.html#left-outer-joins
	# Author.left_outer_joins(:posts).distinct.select('authors.*, COUNT(posts.*) AS posts_count').group('authors.id')

	# Article.includes(:category, :comments)
	# 13.1 Eager Loading Multiple Associations
	# This loads all the articles and the associated category and comments for each article.

	

	scope :is_group, -> {where("is_group = ?",true)}

	scope :scoped, -> {where("sources.id=?",0)}
	scope :snippets, -> {select("#{News.sel_sql},#{News.scores_sql}")}
	#scope :with_topics, -> {joins(:source_topics).where('source_topics.item_id is not null')}
	scope :with_topics, -> {joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")}
	scope :no_topics, -> {joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id").where('source_topics.item_id is null')}
	scope :with_topics_exists, -> {joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id").where('source_topics.item_id is not null')}

	scope :matching, -> (word,limit) { where("title LIKE ? AND NOT urlToImage IS NULL AND NOT urlToImage = ''",word).limit(limit)}
	scope :loosematch, -> (word) { where("(title LIKE ? OR description LIKE ?) AND NOT urlToImage IS NULL AND NOT urlToImage = ''",word,word)}
	scope :has_category, -> (cat) { where("(source_topics.item_id = ?",cat)}
	scope :sortByPublished, -> (order_dir) {order("sources.published_at DESC")}

	scope :byOrg, -> (org_id) { where("orgs.id = ?", org_id)}

	scope :not_ad, -> {(where("`is_ad` IS NOT ? ",true)) }
 	scope :not_spam, -> {(where("is_spam IS NOT ? ",true)) } #scope :not_spam, -> {(where("`is_spam` IS NOT ? ",true)) }
 	scope :not_duplicate, -> {(where("is_duplicate IS NOT ? ",true)) } #scope :not_duplicate, -> {(where("`is_duplicate` IS NOT ? ",true)) }
 	#scope :with_image, -> {(where("`urlToImage` IS NOT NULL AND NOT urlToImage = ''")) } #worked with sqlite
 	scope :with_image, -> {(where("urlToImage IS NOT NULL AND NOT urlToImage = ''")) }

 	scope :with_orgs, -> {joins("LEFT JOIN orgs ON orgs.id = sources.org_id")}
 	scope :with_content, -> {joins("LEFT JOIN contents ON contents.source_id = sources.id")}
	scope :with_summaries, -> {joins("LEFT JOIN summary_sources ON summary_sources.source_id = sources.id").joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")}
	
	scope :by_created_date_as_date, -> (order_desc) {order_desc ? order("DATE(sources.created_at) DESC") : order("DATE(sources.created_at) ASC")}
	scope :by_published_date_as_date, -> (order_desc) {order_desc ? order("DATE(sources.published_at) DESC") : order("DATE(sources.published_at) ASC")}
	scope :by_published_date, -> (order_desc) {order_desc ? order("sources.published_at DESC") : order("sources.published_at ASC")}
	
	scope :published_after, -> (within_hrs) {where("sources.published_at >= ?",(Date.today - within_hrs.hour).to_datetime)}
	scope :published_before, -> (start_hrs) {where("sources.published_at <= ?",(Date.today - start_hrs.hour).to_datetime)}
	scope :is_published, -> {where("NOT summaries.post_mc_guid IS NULL")}
	scope :is_unpublished, -> {where("summaries.post_mc_guid IS NULL")}
	scope :has_summary, -> {where("NOT summaries.id IS NULL")}
	scope :no_summary, -> {where("summaries.id IS NULL")}
	
  def self.unrated within_days: 2, target_type: "Newsify::Source"
    Source.joins("LEFT OUTER JOIN votes ON votable_id = sources.id AND votable_type = '#{target_type}'")
    .where("votable_id is NULL")
    .where("sources.created_at > ?",within_days.days.ago)
  end

	LABELS = ["spam","clickbait","ad","product","foreign"]

	def voted_value user, vote_scope="interesting"
		user.voted_up_on?(self,vote_scope: vote_scope) ? true : (user.voted_down_on?(self,vote_scope: vote_scope) ? false : nil)
	end

	def as_json(options = {})
	  super(options).tap do |json|
	  	unless options[:vote_scopes].nil?
	  	options[:vote_scopes].each do |vote_scope|
		    json[vote_scope.to_sym] = voted_value(options[:user],vote_scope)
			end
			end
	  end
	end


	def opinions
		SourceOpinion.select("source_opinions.*,opinions.title").joins("LEFT JOIN opinions ON source_opinions.opinion_id = opinions.id").where("source_id = ?",self.id)
	end

	def youtube_key
		Source.parse_youtube_full(self.url)[2] unless self.url.nil?
	end

	def summarized? user = nil
		if user.nil?
			self.summary_sources.exists?
		else
			self.summary_sources.joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")
			.where("createdby = ?",user.id).exists?
		end
	end
	def is_summarized? user:
		res = {by_you: false, summarized: false}
		
		res[:by_you] = user.nil? ? false : self.summarized?(user)
		if res[:by_you] || self.summarized?
			res[:summarized] = true
		end
		res
	end

	# includes unique sources
	def self.unique_sources created_after: 24.hours.ago, import_id: nil

		data = Source.where(id:SourceGroup.all.pluck(:source_id))
		data = data.or(Source.where(group_id:nil))
		data = data.where("created_at > ?",created_after) unless created_after.nil?

		data = data.order(:group_id)

		data = data.where(id:ImportSource.where(import_id:import_id).pluck(:source_id)) unless import_id.nil?
		
		data = data.sort_by{|source| source.similar_sources.nil? ? -1 : source.similar_sources.count}.reverse
	end

	# loops through all words looking for youtube links to convert
  	# if a youtube link is found, it pulls it out
	#return arr[0] = content, arr[1] = link, arr[2] = yt_key
	def self.parse_youtube_full content
		result = []
		result[0] = content
		result[1] = nil
		result[2] = nil

		all_words = content.split(" ") unless (content.nil? || content == "")

	  logger.debug "content = #{content}"	
		logger.debug "arr = #{all_words}"
		new_arr = []
		link_found = false
		
		yt_key = nil

		if !all_words.nil? && all_words.length > 0
			all_words.each do |part|

				link = nil
				if !link_found && part.length > 8
					
					if part.index("https://www.youtube.com/embed/") == 0 #1bo-bi5JuLM)
						result[2] = part[("https://www.youtube.com/embed/".length)..(part.length)]
						result[1] = part
						link = result[2]
					#else
		          	elsif part.index("https://www.youtube.com/watch?v=") == 0
		            result[2] = part[("https://www.youtube.com/watch?v=".length)..(part.length)]
		            result[1] = "https://www.youtube.com/embed/" + result[2] #part
		            link = result[2]
					elsif part.index("https://youtu.be/") == 0
		          	regex = /(?:.be\/|\/watch\?v=|\/(?=p\/))([\w\/\-]+)/
				   		begin
				   			yt_key = part.match(regex)[1]
				   			result[1] = "https://www.youtube.com/embed/" + yt_key
				   			result[2] = yt_key
				   			link = yt_key
				   		rescue => ex
	  						logger.debug "remove_youtube regex error: #{ex.message}"
	  						#logger.error ex.message

					   	end
				   		#matches = part.match(regex)
				   		#link = matches[1] if (!matches.nil && matches.length > 0)
					end
				end
			   	
			   	unless link.nil?
			   		link_found = true	
				else
					new_arr.push part #return content
				end
			end
		end


		if link_found
			result[0] = new_arr.join(" ")
		else
			result[0] = content
		end

		return result
	end

	def is_video?
		self.url.blank? ? false : self.url.downcase.include?("youtube.com/watch")
	end

	def google_classify! entities: false, min_salience: 0.0, ga: nil, full_scan: false
		ga = GoogleAnalyze.new if ga.nil?
    	#@sentiment = ga.sentiment_from_text text_content: "I just ate a delicious meal at a restaurant"
    	errors = []
    	begin
    		if self.to_classify.scan(/\w+/).size >= 20
		    	@classified = ga.classify_from_text text_content: (full_scan ? self.to_classify_full : self.to_classify)
		    	@classified.each do |row|
		      		self.add_google_category row[:name], row[:confidence]
		#      {:name=>"/News/Politics", :confidence=>0.9399999976158142}
		    	end
	    	end
    	rescue Exception => e
    		errors.push e
    	end
    	rows = self.google_get_entities! min_salience: min_salience, ga: ga if entities
    	return {errors: errors, rows: rows}
	end

	def google_get_entities! min_salience: 0.0, ga: nil
      ga = GoogleAnalyze.new if ga.nil?
      rows = []
      begin
      data = ga.entities_from_text text_content: self.to_classify
      
      data.each do |entity|
        #new_row = {name: entity.name,:type=>entity.type,:salience=>entity.salience,:wiki_url=>entity.metadata['wikipedia_url']}
        wiki_url = entity.metadata['wikipedia_url'].to_s if entity.metadata['wikipedia_url']
        row = Newsify::EntityRow.new({name: entity.name.to_s,type: entity.type.to_s,salience: entity.salience,wiki_url: wiki_url})
        rows.push row
      end
      self.add_entity_rows rows: rows, min_salience: min_salience
      rescue Exception => e

      end
      rows
	end

	def to_classify
		"#{self.title} #{(self.description.blank? ? "" : self.description)}"
	end
	def to_classify_full
		content.nil? || content.length == 0 ? to_classify : (to_classify + " " + content.first.article)
	end
	def add_google_category label, score, category = true
		classifier = SourceTopic::CLASSIFIERS.find_index("Google:classify")
		item = Item.by_google_category label
		SourceTopic.create(source_id:self.id,item_id:item.id,score:score,classifier:classifier,category: true) unless item.nil? || SourceTopic.where(source_id:self.id,item_id:item.id).exists?
	end
	def add_entity_rows rows:, min_salience: 0.3
		ignore_itypes = ["NUMBER"]
		classifier = SourceTopic::CLASSIFIERS.find_index("Google:entities")
		item_keys = {}
		rows.each do |row|
			item = nil
			item_key = "#{row.name.downcase}#{row.type}#{row.wiki_url}"
			unless row.wiki_url.blank?
				item = Item.where(wiki_url: row.wiki_url).first
				item.update(itype: row.type) if !item.nil? && item.itype.blank?
				item = Item.create(name:row.name,itype:row.type,wiki_url:row.wiki_url) if item.nil? && !item_keys.has_key?(item_key)
			else
				unless item_keys.has_key?(item_key)
					item = Item.create(name:row.name,itype:row.type) if !ignore_itypes.include?(row.type) && (row.salience >= min_salience) && !Item.where("LOWER(name) = ? AND itype = ?",row.name.downcase,row.type).exists?
				end
			end
			
			if !item_keys.has_key?(item_key) && !item.nil? && !SourceTopic.where(source_id:self.id,item_id:item.id).exists?
				SourceTopic.create(source_id:self.id,item_id:item.id,score:row.salience,classifier:classifier)
			end

			item_keys[item_key] = true
		end
	end

	def card_text
		"<div class='font-weight-bold'>#{self.title}</div>" +
		"<div class='text-secondary'>#{self.description}</div>"
	end

	def self.cached_obj source_id, refresh=false
		Source.find_by(id: source_id)
	end
	def self.ors words, title="title"
		data = Source.scoped
		words.each do |q|
			data = data.or(Source.loosematch(q)) #{}"title LIKE ? AND NOT urlToImage IS NULL AND NOT urlToImage = ''",q)) # = @test_data.send("matching",q,10)
		end
		return data.with_image.not_spam.not_duplicate.sortByPublished(true)
	end

	# get score based on interests, add item to guess scope
	# 1st) Get all user interests (2000 of them)
	# 2nd) loop through sources, then topics for each source
	# 3rd) build a score for each source
	# 4th) generate a reason, which is just a list of TOP ITEMS
	def self.guess_interest! user, sources, interests_hash = nil, guesser_id = 0, target_type: "Newsify::Source"
		guesses = {}
		interests_hash = ItemInterest.by_user user, limit: 2000, as_hash: true if interests_hash.nil?
		scope_name = "interesting"
		Community::GuessScope.where("user_id = ? AND scope = ?",user.id,scope_name).delete_all
		
		sources.each do |source|
			score = 0
			top_items = {}
			source.topics.each do |item|
				if interests_hash.has_key?(item.id)
					score+=interests_hash[item.id]
					if interests_hash[item.id] >= 2
						top_items[item.id] = (1000*interests_hash[item.id].to_i)/1000
					end
				end
			end
			
			reason = top_items.length == 0 ? nil : ({"items":top_items.sort_by{|item,v| -v} }).to_json.to_s
			source.guess_score = score
			source.reason = reason
			guesses[source.id] = score
			Community::GuessScope.create(target_type:target_type,target_id:source.id,user_id:user.id,published_at:source.published_at,score:score,scope:scope_name,guesser_id:guesser_id, reason: reason)
		end
		sources = sources.sort_by {|source| -source.guess_score }

	end

	def first_content
		self.content.first
	end
	def last_content
		self.content.last
	end
	def content
		Content.select("id,title,article,misc")
		  .where("source_id = ?",self.id)
	end

	def summaries
		Summary.select("summaries.*")
		.joins("LEFT JOIN summary_sources ON summary_sources.summary_id=summaries.id")
		.where("source_id = ?",self.id)
	end

	def authors
		return Author.select("authors.*").joins("LEFT JOIN source_authors ON source_authors.author_id = authors.id")
		.where("source_id = ?",self.id)
	end

	def org
		return Community::Org.select("*").where("id = ?",self.org_id).first
	end
	def summary_count
		Summary.joins("LEFT JOIN summary_sources ON summary_sources.summary_id=summaries.id")
		.where("source_id = ?",self.id).count
	end

	def self.summary_count source_id
		return SummarySource.where("source_id=?",source_id).count
	end

	def self.by_category category_id, limit=200
		if category_id == 1044
			#category_ids = Item.where("LOWER(itype) IN (?)",["dj","singer"]).pluck(:id)
			_data = Item.popular(category_id,20,0,true)
			category_ids = _data.collect { |v| v.id}
		else
			category_ids = [category_id]
		end

		#categories = Item.where("id IN (?)",category_ids).pluck(:id)
		
		data = Source.snippets.with_topics #_exists
		.with_orgs.with_content.sortByPublished(true)
		.where("source_topics.item_id IN (?)",category_ids)
		.limit(limit)
		#categories.each do |c|
		#	data = data.or(Source.snippets.with_topics.has_category(c.id))
		#end
		return data #.with_orgs.with_content.sortByPublished(true)
	end

	# for chaining scopes dynamically
	def self.send_chain(methods)
	  methods.inject(self, :send)
	end

	def self.send_chain_complex(methods)
		methods.inject { |method| self.send(method[:name],method[:param],method[:limit]) }   
	  	#methods.inject(self, :send)
	end

	def has_label lbl
		(self.attributes["is_#{lbl}"] == true || self.attributes["is_#{lbl}"] == 1) ? true : ( (self.attributes["is_#{lbl}"] == false || self.attributes["is_#{lbl}"] == 0) ? false : nil)
	end
	def author_count 
		return Source.author_count self.id
	end
	def self.author_count source_id
		return SourceAuthor.where("source_id=?",source_id).count
	end

	def authors
		return Author.select("authors.id,authors.name")
			.joins("LEFT JOIN source_authors ON source_authors.author_id = authors.id")
			.where("source_id = ?",self.id)
	end



	def self.is_spam source_id, is_spam=true, spam_score = nil
		s = Source.where("id = ?",source_id)
		s.is_spam = is_spam == true ? true : false
		s.spam_score = spam_score if !spam_score.nil?
		s.save
	end

	def flag_as_spam spam_score=nil,is_spam=true
		self.is_spam = is_spam
		self.spam_score = spam_score if !spam_score.nil?
		self.save
	end

	def self.topic_count source_id
		return SourceTopic.where("source_id=?",source_id).count
	end

	def self.content_count source_id
		return Content.where("source_id=?",source_id).count
	end

	def self.topics source_id,  args= {min_score: 0.05, max_score: 1.0}
		items = SourceTopic.select("items.id,source_topics.item_id,items.parent_id,items.name,items.wd_descr,items.wiki_text,source_topics.createdby,items.fame,items.relevance,source_topics.score,source_topics.approved,source_topics.category as is_category")
		.joins("LEFT JOIN items ON source_topics.item_id = items.id")
		.where("source_topics.source_id = ? AND source_topics.score >= ? AND source_topics.score<= ?",source_id,args[:min_score],args[:max_score])
		.order("score DESC")

		return items
	end

	def cached_topics refresh=false, cache_expiration=60000
		return Source.cached_topics self.id, refresh, cache_expiration
	end

	def self.cached_topics source_id, refresh=false,cache_expiration=60000
		return Cache.get_source_topics source_id, refresh, cache_expiration
	end

	def all_topics
		return Source.topics(self.id, {min_score: 0.0, max_score: 1.0})
	end
	#def self.all_topics
	#	return Source.topics(self.id, {min_score: 0.0, max_score: 1.0})
	#end
	def topics min_score: 0.05, max_score: 1.0
		return Source.topics(self.id, {min_score: min_score, max_score: max_score})
	end

	def topic_ids

		item_ids = SourceTopic.select("items.id as item_id,items.name")
		.joins("LEFT JOIN items ON source_topics.item_id = items.id")
		.where("source_topics.source_id = ?",self.id).pluck(:item_id)
		return item_ids
	end

	def self.article_count_by_term query, use_cache=true, refresh=false,cache_expiration=60000
      	if query.nil?
      		return 0
      	else
      		if use_cache
    			return Cache.article_count_by_query query, refresh, cache_expiration
    		else
			  	name_q = "%"+query.downcase+"%"
			    return Source.select("*")
			    .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")
			    .where("lower(sources.title) LIKE ? OR lower(sources.description) LIKE ?",name_q,name_q).count
    		end
    	end
    end

     def self.articles_by_summary_id summary_id, limit=100, offset=0, use_cache=false,refresh=false, cache_expiration=60000
    	if summary_id.nil?
    		return []
    	else
    		if false && use_cache
    			#return Cache.search_articles query.downcase, limit, offset, refresh, cache_expiration
    		else
		    	return Source.select("DISTINCT(sources.id),sources.id as source_id,orgs.name as source_name,sources.*,contents.edited, contents.id as content_id")
			    .joins("LEFT JOIN summary_sources ON summary_sources.source_id = sources.id")
			    .joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")
			    .joins("LEFT JOIN contents ON contents.source_id = sources.id")
			    .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")
			    .joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			    .where("summary_sources.summary_id = ?",summary_id)
			    .offset(offset)
			    .order("published_at DESC")
			    .limit(limit)
			end
		end
    end

    def self.articles_by_term query, limit=100, offset=0, use_cache=false,refresh=false, cache_expiration=60000
    	if query.nil?
    		return []
    	else
    		if use_cache
    			return Cache.search_articles query.downcase, limit, offset, refresh, cache_expiration
    		else
		    	name_q = "%"+query.downcase+"%"
		    	return Source.select("DISTINCT(sources.id),sources.id as source_id,orgs.name as source_name,sources.*,contents.edited, contents.id as content_id")
			    .joins("LEFT JOIN contents ON contents.source_id = sources.id")
			    .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")
			    .joins("LEFT JOIN orgs ON orgs.id = sources.org_id")
			    .where("lower(sources.title) LIKE ? OR lower(sources.description) LIKE ?", name_q,name_q)
			    .offset(offset)
			    .order("published_at DESC")
			    .limit(limit)
			end
		end
    end

    def self.article_ids_by_term query, limit=100, offset=0, use_cache=false,refresh=false, cache_expiration=60000
    	if query.nil?
    		return []
    	else
    		if use_cache
    			return Cache.search_article_ids query.downcase, limit, offset, refresh, cache_expiration
    		else
		    	name_q = "%"+query.downcase+"%"
		    	return Source.select("DISTINCT(sources.id) as source_id")
			    .where("lower(sources.title) LIKE ? OR lower(sources.description) LIKE ?", name_q,name_q)
			    .offset(offset)
			    .order("published_at DESC")
			    .limit(limit).pluck(:source_id)
			end
		end
    end
	
	# pointless topics are tags/topics that are not very interesting
	def purge_pointless_topics dry_run=false,logger=nil

		pointless_itypes = ["dowecare", "validity", "dowecare", "basicinfo", "concept"] #complaint"
		pointless_ids = Item.where("itype IN (?)",pointless_itypes).pluck(:id)
		
		result = {:article_id=>self.id,:pointless_ids=>pointless_ids,:removed=>[]}

		unless logger.nil?
			logger.debug pointless_ids
		end
			item_ids = SourceTopic.select("source_topics.id,items.id as item_id,items.name")
			.joins("LEFT JOIN items ON source_topics.item_id = items.id")
			.where("source_topics.source_id = ?",self.id)
			item_ids.each do |st|
				logger.debug "EXAMINING: #{st.item_id}"

				if pointless_ids.include? st.item_id
					logger.debug "CHECKING: #{st.item_id}"
					if st.id > 0
						logger.debug "REMOVING: #{st.item_id}"
						result[:removed].push(st.item_id)
						if !dry_run
							SourceTopic.delete(st.id)
						end
					end
				end
			end
		
		return result
	end


	def purge_duplicate_topics
					  # before removing, we make sure the topic already exists
		safe_ids = [] #once we check to see if the topic exists, we add it to this array

		res = {:removed=>[],:keys=>[],:count=>0}

		item_ids = SourceTopic.select("source_topics.id,items.id as item_id,items.name,items.itype,items.wiki_url")
		.joins("LEFT JOIN items ON source_topics.item_id = items.id")
		.where("source_topics.source_id = ?",self.id)
		res[:count] = item_ids.length
		item_ids.each do |st|
			topic_key = "#{st.item_id}#{st.itype}#{st.wiki_url}"
			res[:keys].push topic_key
			if safe_ids.include? topic_key
				if st.id > 0
					SourceTopic.delete(st.id)
					res[:removed].push st.id
				end
			else
				safe_ids.push topic_key
			end
		end
		return res
	end

	def self.by_summary_id summary_id
		return Source.select("sources.*")
		.joins("LEFT JOIN summary_sources ON summary_sources.source_id=sources.id")
		.where("summary_sources.summary_id = ?",summary_id).first
	end

	def self.by_summary_ids summary_ids
		return Source.select("sources.*")
		.joins("LEFT JOIN summary_sources ON summary_sources.source_id=sources.id")
		.where("summary_sources.summary_id IN (?)",summary_ids)
	end

	def self.by_summary_post_mc_guids summary_post_mc_guids, indexed=false
		data = Source.select("sources.*,summaries.title as summary,summaries.post_mc_guid")
		.joins("LEFT JOIN summary_sources ON summary_sources.source_id=sources.id")
		.joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")
		.where("summaries.post_mc_guid IN (?)",summary_post_mc_guids)
		
		if indexed

			_idx = {}
			data.each do |d|
				_idx[d.post_mc_guid] = d
			end
			return _idx
		else
			return data
		end

	end

	def self.merge_sources from_id, to_id, dry_run = false

		Source.sync_sources(to_id, [from_id,to_id])
		#remove 

		summaries = SummarySource.where("source_id = ?",from_id)
		summaries.update_all(source_id: to_id)

		authors = SourceAuthor.where("source_id = ?",from_id)
		authors.each do |author|
			unless SourceAuthor.exists?(:source_id => to_id,:author_id =>author.author_id)
				sa = SourceAuthor.new(:source_id=>to_id,:author_id=>author.author_id)
				sa.save
			end
		end

		if Content.exists?(:source_id => from_id)

			old_content = Content.where("source_id = ?",from_id).first
			
			#TODO: archive the CONTENT being removed
			Content.where("source_id=?",to_id).destroy_all
			old_content.update(source_id: to_id)

		else


		end
	end


	#an array of source ids with no content, no summaries and more than 0 topics
	def self.prioritize_source maybe_save, sync_topics = true

		max_topics = 0
		topic_counts = {}
		
		all_topics = {}

		maybe_save.each do |source_id|
			tc = Source.topic_count(source_id)
			topic_counts[source_id] = tc
			if tc > max_topics
				max_topics = tc
			end
			if tc > 0 && sync_topics
				topic_ids = SourceTopic.where("source_id = ?",source_id).pluck(:item_id)
				topic_ids.each do |topic_id|
					all_topics[topic_id]=true
				end
			end
		end
		logger.debug "sorted: #{topic_counts.inspect}"
		sorted = topic_counts.sort_by{ |k, v| v }.reverse

		prioritized_source_id = sorted[0][0]

		#make sure all the items have the same topics
		if sync_topics
			all_topics.each do |key, val|
				if SourceTopic.where("source_id = ? AND item_id = ?",prioritized_source_id,key).count == 0
					st = SourceTopic.new(:source_id =>prioritized_source_id,:item_id=>key)
					st.save
				end
			end
		end

		return prioritized_source_id
	end

	# checks if target_id is missing topics or authors
	#TODO: add author syncing
	def self.sync_sources target_id, dup_ids
		all_topics = {}

		dup_ids.each do |source_id|
			unless source_id == target_id
				tc = Source.topic_count(source_id)
				if tc > 0
					topic_ids = SourceTopic.where("source_id = ?",source_id).pluck(:item_id)
					topic_ids.each do |topic_id|
						all_topics[topic_id]=true
					end
				end
			end
		end

		add_count = 0
		err_count = 0

		all_topics.each do |key, val|
			if SourceTopic.where("source_id = ? AND item_id = ?",target_id,key).count == 0
				st = SourceTopic.new(:source_id =>target_id,:item_id=>key)
				if st.save
					add_count+=1
				else
					err_count+=1
				end
			end
		end
		logger.debug "TOPICS ADDED for #{target_id} [#{add_count} with #{err_count} errors]"
	end
	
	def self.article_count item_id,recent_hours=24
		recent_date = (DateTime.now.utc - recent_hours.hours)
      	start_date = recent_date.strftime('%Y-%m-%d %H:%M:%S')
      	#start_date = Time.zone.now.beginning_of_day
#      	date_sql = " AND sources.published_at > '#{start_date}'"

      	return Source.select("count(sources.id) as article_count")
      	.joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")
      	.joins("LEFT JOIN items ON source_topics.item_id=items.id")
      	.where("items.id = ? AND sources.published_at >= ? AND (sources.is_duplicate = ? OR sources.is_duplicate is null)",item_id,start_date,false).first
	end

	def self.recent_articles item_id,recent_hours=24,sample_size=1

		recent_date = (DateTime.now.utc - recent_hours.hours)
      	start_date = recent_date.strftime('%Y-%m-%d %H:%M:%S')

		articles = Source.select("sources.*,contents.id as content_id,contents.edited,contents.article")
            .joins("LEFT JOIN contents ON contents.source_id = sources.id")
            .joins("LEFT JOIN source_topics ON source_topics.source_id=sources.id")
            .where("source_topics.item_id=? AND sources.published_at >= ?",item_id,start_date)
            .order("sources.published_at DESC")

        return articles.sample(sample_size)
	end

	def self.to_summarize item_id,recent_hours=24,sample_size=1

		recent_date = (DateTime.now.utc - recent_hours.hours)
      	start_date = recent_date.strftime('%Y-%m-%d %H:%M:%S')

		articles = Source.select("sources.*,contents.id as content_id,contents.edited,contents.article")
            .joins("LEFT JOIN contents ON contents.source_id = sources.id")
            .joins("LEFT JOIN source_topics ON source_topics.source_id=sources.id")
            .joins("LEFT JOIN summary_sources ON summary_sources.source_id=sources.id")
            .joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")
            .where("source_topics.item_id=? AND sources.published_at >= ? AND summary_sources.id is NULL AND summaries.id is NULL",item_id,start_date)
            .order("sources.published_at DESC")

        return articles.sample(sample_size)
	end

	# returns sources (an array of newly created sources AND those that match the hash of title and description)
	def self.import_news news_json, createdby, options, logger=nil

		logger.debug "inside import_news" unless logger.nil?
		

		fields = options[:fields] || ["org","author","source","topic"]
		item_id = options[:item_id] && options[:item_id] > 0 ? options[:item_id] : nil

		require 'digest'

		sources = []

		news_json.each do |news_item|
			logger.debug "inside add new_item" unless logger.nil?
			#org_id = Create or lookup org_id
			org_lookup_only = !(fields.include?("org"))
			org_id = Community::Org.lookup_or_create news_item, createdby, org_lookup_only

			author_ids = Author.add_from_api news_item["author"],"newsapi",org_id, createdby

			is_spam = false
			is_duplicate = false

			logger.debug "outputting news_item" unless logger.nil?
			logger.debug news_item.as_json unless logger.nil?

			# urlToImage changed to urltoimage
			source = Source.new(:org_id=>org_id,:title=>news_item["title"],:description=>news_item["description"],
				:url=>news_item["url"],:url_blocked=>nil,:urltoimage=>news_item["urlToImage"],
				:published_at=>Time.parse(news_item["publishedAt"]),:is_spam=>is_spam,:is_duplicate=>is_duplicate,:createdby=>createdby)
			
			source.title = source.title.strip unless source.title.nil?
	  		source.description = source.description.strip unless source.description.nil?
	  		source_hash_string = ((source.title.nil?) ? "" : source.title) + ((source.description.nil?) ? "" : source.description)
	  		source.hashkey = Digest::SHA256.hexdigest(source_hash_string)
	  		
			source.is_duplicate = Source.exists?(:hashkey => source.hashkey)

			if !source.is_duplicate && fields.include?("source")
				logger.debug "source not duplicate:" unless logger.nil?
				if source.save
					logger.debug "source saved: #{source.id}" unless logger.nil?
					source.add_authors_by_id author_ids
					
					if !item_id.nil? && !SourceTopic.exists?(:source_id => source.id,:item_id =>item_id)
						st = SourceTopic.new(:source_id=>source.id,:item_id=>item_id,:createdby=>createdby)
						st.save
						logger.debug "source topic saved item: #{item_id}" unless logger.nil?
					elsif item_id.nil?
						# do we want to save headlines under one TOPIC??
						logger.debug "source topic item is null" unless logger.nil?
					end
					sources.push source
				end
			else
				logger.debug "source is duplicate, or source missing:" unless logger.nil?
				if !item_id.nil? && fields.include?("topic") && source.is_duplicate
					old_sources = Source.select("*").where("hashkey = ?",source.hashkey)
					old_sources.each do |old_source|
						unless SourceTopic.exists?(:source_id => old_source.id,:item_id =>item_id)
							st = SourceTopic.new(:source_id=>old_source.id,:item_id=>item_id,:createdby=>createdby)
							st.save
							logger.debug "source topic saved item: #{item_id}" unless logger.nil?
						end
						sources.push old_source
					end
				end
				if fields.include?("date") && source.is_duplicate
					#logger.debug "updating date" unless logger.nil?

					old_sources = Source.select("*").where("hashkey = ?",source.hashkey)
					old_sources.each do |old_source|
						#logger.debug "updating source: #{old_source.id}" unless logger.nil?

						old_source.published_at = source.published_at
						old_source.save
						logger.debug "inside old_source save #{old_source.id}" unless logger.nil?
						#SourceAuthor.where("source_id = ?",old_source.id).delete_all
						#old_source.add_authors_by_id author_ids
					end
				end

				if fields.include?("author") && source.is_duplicate
					old_sources = Source.select("*").where("hashkey = ?",source.hashkey)
					old_sources.each do |old_source|
						#SourceAuthor.where("source_id = ?",old_source.id).delete_all
						old_source.add_authors_by_id author_ids
					end
				end
			end
		end

		return sources
	end

	

	def add_authors_by_id author_ids
		contrib_score = 1.to_f/author_ids.length
		author_ids.each do |aid|
			unless SourceAuthor.exists?(:source_id=>self.id,:author_id=>aid)
				sa = SourceAuthor.new(:source_id=>self.id,:author_id=>aid,:contrib_score=>contrib_score)
				if sa.save

				end
			end
		end
	end



end
end