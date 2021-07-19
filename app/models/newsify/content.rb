module Newsify
	class Content < ActiveRecord::Base
		self.table_name = "contents"

		include Newsify::TextUtil, Newsify::GenericObj, Classify::ClassifyContent

		scope :with_sources, -> {joins("LEFT JOIN sources ON sources.id=contents.source_id")}
		scope :with_orgs, -> {joins("LEFT JOIN orgs ON orgs.id = sources.org_id")}
		scope :with_summaries, -> {joins("LEFT JOIN summary_sources ON summary_sources.source_id = sources.id").joins("LEFT JOIN summaries ON summaries.id = summary_sources.summary_id")}
		scope :by_created_date_as_date, -> (order_desc) {order_desc ? order("DATE(sources.created_at) DESC") : order("DATE(sources.created_at) ASC")}
		
		scope :by_published_date, -> (order_desc) {order_desc ? order("sources.published_at DESC") : order("sources.published_at ASC")}
		scope :by_published_date_as_date, -> (order_desc) {order_desc ? order("DATE(sources.published_at) DESC") : order("DATE(sources.published_at) ASC")}

		scope :published_after, -> (within_hrs) {where("sources.published_at >= ?",(Date.today - within_hrs.hour).to_datetime)}
		scope :published_before, -> (start_hrs) {where("sources.published_at <= ?",(Date.today - start_hrs.hour).to_datetime)}

		scope :byOrg, -> (org_id) { where("orgs.id = ?", org_id)}
		scope :is_published, -> {where("NOT summaries.post_mc_guid IS NULL")}
		scope :is_unpublished, -> {where("summaries.post_mc_guid IS NULL")}
		scope :has_summary, -> {where("NOT summaries.id IS NULL")}
		scope :no_summary, -> {where("summaries.id IS NULL")}
		
		
		def self.time_saved article
			chars_per_word = 4.5
			words_per_minute = 250
			words_per_second = 250/60.0

			if article.source_chars.nil? || article.title.nil?
				return {:status=>false}
			else
				start_words = (article.source_chars/chars_per_word).to_i
				summary_words = (article.title.length/chars_per_word).to_i
				saved_words = start_words-summary_words
				saved_seconds = (saved_words/words_per_second)
				output = {:status=>true,:text=>"",:saved_seconds=>saved_seconds}
				output[:text] = "You saved " + (saved_seconds > 60 ? ((saved_seconds/60).round(1).to_s + " mins") : (saved_seconds.round(0).to_s + " seconds"))
				return output
				#return "#{start_words} words reduced to #{summary_words} words"
			end
		end

		def cached_topics refresh=false, cache_expiration=60000
			return Source.cached_topics self.source_id, refresh, cache_expiration
		end

		#TODO: improve best_guesses (it is kind of a hack to work with scraperapi)
		# get web content
		# use preview text to build collection of 'best_guesses' content
		# renamed/moved from Search.web_content
		def self.from_web url, preview, logger=nil

			# Fetch and parse HTML document
			full_url = 'http://api.scraperapi.com/?key=c4932d4260c5e434ab725c34ef95f055&url=' + url
			
			#logger.debug "URL: " + full_url

			require 'nokogiri'
			require 'open-uri'
			doc = Nokogiri::HTML(open(full_url))
			#doc_body = doc.

			output = {'best_guesses'=>[],'results'=>[]}
			# look for the article
			doc.css('script').remove 
			doc.css('style').remove  

			results = []
			doc.css('div').each do |div|
			  #logger.debug div.content
			  output['results'].push(div.content.squish) #.gsub(/\s+/, ""))
			  if div.content.include?(preview)
			    posOfSubString = div.content.index(preview)
			    #string[N..-1]
			    output['best_guesses'].push(div.content[posOfSubString..-1].squish)
			  end
			end

			unless logger.nil?
				logger.debug "api call result:"
				logger.debug output['results']
			end
	      output['results'] = output['results'].sort_by {|x| -x.length}

	      return output
	      #@results = results


		end

		def self.save_content source, output

	        content = Content.new
	        content.source_id = source.id

	        content.title = source.title
	        content.article = output['best_guesses'][0]
	        content.misc = output.to_json
	        content.edited = false
	        content.save
		end

		
		def self.save_parsed_content source, article_text, summary

	        content = Content.new
	        content.source_id = source.id

	        content.title = source.title
	        content.article = article_text
	        content.misc = summary #output.to_json
	        content.edited = true #false
	        content.save
		end

	end
end
