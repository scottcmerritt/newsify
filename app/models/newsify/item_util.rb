module Newsify
	class ItemUtil

		def initialize

		end

		# loop through items and calculate relevance based on # of times referenced
		# TODO: fame should be updated based on impressions?? and relevance??
		def self.calc_fame!
			max_tags = SourceTopic.most_tagged_count
			max_impressions = Impression.select("COUNT(impressionable_id) as impression_count")
			.where("impressionable_type = ?","Source").group("impressionable_id").order("impression_count DESC").first.impression_count

			rel_alpha = 0.05*max_tags
			rel2_alpha = 0.05*max_impressions
			
			items = Item.select("items.id,items.name,items.fame,items.relevance,items.wd_id,items.wd_descr,items.wiki_text, items.ambiguous,COUNT(source_topics.id) as tag_count")
			.joins("LEFT JOIN source_topics ON source_topics.item_id = items.id")
			.group("items.id,items.name,items.fame,items.relevance,items.wd_id,items.wd_descr,items.wiki_text,items.ambiguous")
			.order("tag_count DESC")

			items.each do |item|

					# add in impressions AND ItemInterest
					describes_count = 0
					article_count = Source.article_count_by_term item.name, false
					tagged_count = item.tag_count.nil? ? SourceTopic.item_tagged_source_count(item.id) : item.tag_count

					relevance_val1 = (tagged_count.to_f + article_count + describes_count)/(rel_alpha + tagged_count + article_count.to_f + describes_count)
					relevance_val2 = (item.impressionist_count)/(rel2_alpha + item.impressionist_count)
					relevance_val = (relevance_val1 + relevance_val2) / 2

					#logger.debug "relevance: #{relevance_val} #{item.id}" unless logger.nil?

					if relevance_val <= 0
						relevance_val = 0.1
					end
					relevance_val = relevance_val*0.9 if !item.name.nil? && item.name.length < 4
					
					if !item.wiki_text.nil? && item.wiki_text.length > 100

						#fame_val+=0.1 if fame_val < 0.8
						relevance_val = (relevance_val + 0.1) if (relevance_val < 0.8)
					end
					#if fame_val < 0.5
					#	fame_va = (fame_val + 0.1) unless item.wd_id.nil?
					#	fame_val = (fame_val + 0.1) unless item.wd_descr.nil?
					#end

					if relevance_val < 0.5
						#relevance_val = 0.30
						relevance_val = (relevance_val + 0.1) unless item.wd_id.nil?
						relevance_val = (relevance_val + 0.1) unless item.wd_descr.nil?
						relevance_val = (relevance_val + 0.1) if (describes_count > 10)
					end
					if item.ambiguous == true
						#fame_val = fame_val*0.5
						relevance_val = relevance_val*0.5
					end
					item.update(relevance: relevance_val)
				end

		end
	end
end