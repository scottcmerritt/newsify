module Newsify
	# newsapi.org, free = 100/day (100 articles/request)
	# gnews.io, free = 100/day (10 articles/request)
	# Newsdata.io, free = 500 requests/day (10 articles/request)
	# media stack, 500 requests/mo, $25 = 19k requests/mo, $100 = 50k, $250 = 250k
	# News Catcher newscatcherapi.com, 1 req/sec, 1k/mo (if personal email), 10k/mo if work

	# Bing , free = 100/day, .005/request after, cc required

	# Yahoo News Api $1.80/1000 requests

	class Import < ActiveRecord::Base
		self.table_name = "imports"

		#include ActiveModel::Model
		#NEWS_API_KEY = ENV["NEWS_API_KEY"] 
		has_many :import_sources, dependent: :destroy, inverse_of: :import
		
		scope :recent, -> {order("id DESC")}	

		def user
			User.find_by(id: self.user_id)
		end

		#TODO: consider moving Source.import_news here

		# TODO: get this working in the background

		def self.auto_import! logger = nil, api_key:, use_proxy: Import.use_proxy?
			user_id = -1
			@terms = ["headlines","dating", "tech","tennis","soccer","summer","open source software","software","dating","startup","acquired","music","entrepreneur","tech","business","education","fullerton","orange county","california"]
			term = @terms[0]
			Import.start_import({:max_pages=>1,:page=>1,:q=>term},user_id, logger,use_proxy:use_proxy)
		end

		def self.use_proxy?
			(ENV['NEWSIFY_USE_PROXY'] && [true,"true"].include?(ENV['NEWSIFY_USE_PROXY'])) ? true : false
		end

		# determine if the articles have been grouped
		def grouped?
			ImportSource.joins("LEFT JOIN sources ON sources.id = import_sources.source_id").where("import_sources.import_id = ? AND sources.group_id > 0",self.id).count > 0
			#self.import_sources.joins("LEFT JOIN sources ON sources.id = import_sources.source_id").exists?(sources: {group_id:!nil}) ? true : false
		end

		def source_previews
			Source.unique_sources created_after: nil, import_id: self.id
		end

		def classify!
			 ga = GoogleAnalyze.new
		      self.import_sources.each do |import_source|
		          source = import_source.source
		          if source.topics.length == 0
		            res = source.google_classify! entities: true, min_salience: 0.01, ga: ga
		            #@items = @items + res[:rows]
		            #@errors = @errors + res[:errors]
		            #@classified.push source.id
		            self.import_pct true
		          end
		      end
		end

		def import_pct refresh = false
			cached = Newsify::Cache.import_pct(self.id)
			if refresh || !cached
				count = 0
				imported = 0
				self.import_sources.each do |is|
					if is.source.source_topics.length  > 0
						imported+=1
					end
					count+=1
				end
				val = imported.to_f/count
				Newsify::Cache.save_import_pct! self.id, val
				return val
			else
				return cached
			end
		end


		# EXAMPLES: 
		# 'https://newsapi.org/v2/everything?q=bitcoin&from=2019-02-20&sortBy=popularity&language=en&page=1&apiKey='
		# https://newsapi.org/v2/top-headlines?sources=bbc-news&apiKey=
		# https://newsapi.org/v2/everything?q=bitcoin&page=1&apiKey=
		# sortBy = popularity or publishedAt  #'from=2019-03-06&'\
		def self.news_from_api search_term = nil, params={}, logger=nil, use_proxy:true, api_key:
			require 'open-uri'
			page_num = params[:page] ? params[:page].to_i : 1

			search_path = (search_term.nil? || search_term == "headlines") ? "top-headlines" : "everything" #unless search_term.nil?
			search_param = (search_term.nil? || search_term == "headlines") ? nil : "q="+search_term #+"&"

			url = 'https://newsapi.org/v2/'+search_path
			url+=search_term.nil? ? '?country=us' : '?sortBy=publishedAt&language=en'
			
			url+="&page=#{page_num}"
			url+="&#{search_param}" unless search_param.nil?
			url+='&pageSize=100'
			url+="&apiKey=#{api_key}" #Import::NEWS_API_KEY}"
			logger.debug "NEWS_FROM_API\n #{url}" unless logger.nil?


			if use_proxy
			    url_to_site = ENV["NOCODE_PROXY"] || "http://localhost:3000"
			    path_to_api = ENV["NOCODE_PROXY_PATH"] || "/api/proxy"

			    url = url_to_site+path_to_api+"?api_key=#{ENV["NOCODE_KEY"]}&" + {url: url}.to_query 
			end
			req = URI.open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
			result_json = req.read

			return result_json

=begin
			require 'rest-client'
			

		  	url = "https://newsapi.org/v2/top-headlines"

		  	response = RestClient::Request.execute(
				method: :get,
				url: url,
				headers: {apiKey: api_key}
				)

		  	return JSON.parse(response)
=end
		end

		def add_sources sources
			sources.each do |source|
				self.import_sources.create(source_id: source.id)
			end
		end
		# get articles from news_api, add them to the DATABASE
		def self.start_import params, createdby, logger, api_key:, use_proxy: Import.use_proxy?



			import = Import.create(keyword: params[:q],user_id:createdby,api_id:1)


			options = {}
	  		options[:results_per_page] = 100

	  		search_topic = params[:q] || nil #{}"Google"
	  		
	  		options[:page] = params[:page] || 1

	  		#options[:page] = 1
	  		options[:item_id] = (params[:item_id].to_i > 0) ? params[:item_id].to_i : nil


	  		options[:max_pages] = params[:max_pages] || 200
	  		options[:dryrun] = params[:dryrun] ? true : false
	  		options[:fields] = ["org","date","topic","source"] #"author","source"

		  	news_data = Import.news_from_api(search_topic, options,logger, api_key: api_key,use_proxy:use_proxy)
		  	imported = JSON.parse(news_data)
		  	
		  	# add data from news api to DATABASE
		  	sources = Source.import_news imported["articles"], createdby, options, logger

		  	import.add_sources sources

		  	pages = (imported["totalResults"]/options[:results_per_page]).ceil
	  		pages_retrieved = pages


	  		#TODO: run this in the background

	  		#pages = 20
	  		if pages > 1

	  			#basic limiter to prevent more than 200 calls (for now)
		  		pages = options[:max_pages] if pages > options[:max_pages]

		  		(2..pages).each do |page_num|
		  			options[:page] = page_num

			  		news_data = Import.news_from_api(search_topic, options,logger,use_proxy:use_proxy)
			  		
			  		imported = JSON.parse(news_data)
			  		unless options[:dryrun]
				  		new_sources = Source.import_news imported["articles"], createdby, options, logger
				  		import.add_sources new_sources
				  		sources = sources + new_sources
				  	end

				  	if page_num == pages
						$redis.set("news", news_data)
				  	end
			  	end
			end

			result = {:object=>import,:sources=>sources,:import_count=>imported["articles"].length,:imported=>imported,:pages_retrieved=>pages_retrieved}
			return result


		end
	end
end