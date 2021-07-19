module Classify
	class Summarize < Newsify::BackgroundProcess
	# http://textsummarization.net/text-summarization-api-for-ruby

		 def initialize(attributes={})
		 	super(attributes)

	    	#super
	    	#@omg ||= true
	    
	    # MeaningCloudSummarization 40k free
	    # ML Analyzer 100k free


	    	#@textapi 	= attributes[:json] || nil

	    	# https://github.com/AYLIEN/aylien_textapi_ruby/blob/master/lib/aylien_text_api/client.rb
			require 'aylien_text_api'

			app_id = ENV['AYLIEN_APP_ID'] 
			api_key = ENV['AYLIEN_API_KEY']
			@textapi = AylienTextApi::Client.new(app_id: app_id, app_key: api_key)


			# textapi.sentiment text: "John is a very good football player!"

			#client.extract url: "http://techcrunch.com/2014/02/27/aylien-launches-text-analysis-api-to-help-developers-extract-meaning-from-documents/"

	# => {
	#  :title=>"Aylien Launches Text-Analysis API To Help Developers...",
	#  :article=>"Working with text is often a messy business for...",
	#  :image=>"", :author=>"Frederic Lardinois", :videos=>[],
	#  :feeds=>["http://techcrunch.com/2014/02/27/aylien-...
	#  }
		end

		def classify! text
			# returns {:categories=>[]}
			@textapi.classify! text: text
		end

		def get_summary url, sentences_number

			# {:text=>"hello world",:sentences=>["summary text"]}
			#@textapi.summarize(value=nil, params={})
			response = @textapi.summarize url: url, sentences_number: sentences_number
			return response
		end

		def self.by_url url,source_obj,source_id,api_id = 0,item_ids=[],logger=nil
			_summarize = Summarize.new
			return _summarize.by_url url,source_obj,source_id,api_id,item_ids,logger
		end

		def by_url url,source_obj,source_id,api_id = 0,item_ids=[],logger=nil

			res = {:response=>nil,:summary=>nil,:summary_obj=>nil}
			
			#url = "http://www.thewrap.com/idris-elba-set-to-expand-dj-career-at-edc-las-vegas-2019/"
			res[:response] = get_summary url, 4
			unless res[:response].nil?
				article_txt = res[:response][:text]

				logger.debug "SUMMARY STUFF:" unless logger.nil?
				logger.debug(res[:response][:sentences]) unless logger.nil?

				res[:summary] = res[:response][:sentences].join(" ")
				logger.debug(res[:summary]) unless logger.nil?

				# adds a content record with source_id set to source_id
				# and misc sent to the new summary
				Newsify::Content.save_parsed_content source_obj, article_txt, res[:summary] #@response[:sentences]
				date = source_obj.published_at #Time.parse()

				#TODO: add source_topic_ids to the summary 

				# current_user.id
				res[:summary_obj] = Newsify::Summary.add res[:summary], 0, date, item_ids, article_txt.length #nil #item_id=nil

				if source_id > 0
				 ss = Newsify::SummarySource.new(:summary_id=>res[:summary_obj][:summary].id,:source_id=>source_id)
				 ss.save
				end

				summary_item_ids = res[:summary_obj][:summary].item_ids

				item_ids.each do |item_id|
					if !summary_item_ids.include?(item_id)
						si = SummaryItem.new(:summary_id=>res[:summary_obj][:summary].id,:item_id=>item_id)
						si.save
					end
				end
			end

			return res
		end

		#aylien, 120,000 / month for $150, $449 for 600,000, $999 for 1,500,000
		def self.from_sources sources, summarize_api_id=0,logger = nil, dry_run = false
			_summarize = Summarize.new
			return _summarize.from_sources sources, summarize_api_id, logger, dry_run
		end

		def from_sources sources, summarize_api_id=0,logger = nil, dry_run = false
			feedback = []
			summarized = []
			failed = []
			if !sources.is_a? Array
				sources = [sources]
			end
			
			status_start sources.length, "Summarizing articles: #{sources.length} items"

			sources.each do |source_obj|
				status_incr 1

	        	#check if SummarySource already has a record (summary_id,source_id)
				# if NOT, create SUMMARY

				unless source_obj.nil?

					_summary = Newsify::Summary.select("summaries.id")
					.joins("LEFT JOIN summary_sources ON summaries.id = summary_sources.summary_id")
					.where("summary_sources.source_id = ?",source_obj.id).first
					if _summary.nil?
						status_update "Summarizing article: #{source_obj.title}"

						item_ids = source_obj.topic_ids

		            	#TODO: pass in known items (so summary_items rows can be added)
		            	# AND/OR scan content later and ADD item/summary rows
		            	if dry_run == false
							summary_result = Summarize.by_url source_obj.url,source_obj,source_obj.id,summarize_api_id, item_ids, logger
							response = summary_result[:response]
							
							#@summary = summary_result[:summary]
							#@new_summary = summary_result[:summary_obj]
							if summary_result[:summary].nil?
								feedback.push "Summary failed, for source: " + source_obj.id.to_s
								failed.push source_obj
							else
								feedback.push "Summary created for source: " + source_obj.id.to_s
								summarized.push source_obj
							end
						end
					else
						status_update "Article already summarized: #{source_obj.id}"
						feedback.push "Summary exists for source: " + source_obj.id.to_s
					end
				end
			end

			return {:feedback=>feedback,:summarized=>summarized,:failed=>failed}

		end

	end
end