module Newsify
	class SummaryItem < ActiveRecord::Base
		self.table_name = "summary_items"
		def self.add options={}
			si = SummaryItem.new(options)
			if si.save
				#send notifications to people who watch this item
				return si
			else
				return nil
			end
		end

		def self.by_item item_id, date=nil
			if date.nil?
			select("summary_items.id,summary_id,summaries.title,strftime('%Y-%m-%d',datetime(summaries.date, 'localtime')) as 'SummariesDate'")
			.joins("LEFT JOIN summaries ON summaries.id = summary_items.summary_id")
			.where("summaries.item_id = ? OR summary_items.item_id = ?",item_id,item_id)

			else
			formatted_date = date.strftime('%Y-%m-%d') #,date)
			logger.debug formatted_date
			select("summary_items.id,summary_id,summaries.title,strftime('%Y-%m-%d',datetime(summaries.date, 'localtime')) as 'SummariesDate'")
			.joins("LEFT JOIN summaries ON summaries.id = summary_items.summary_id")
			.where("(summaries.item_id = ? OR summary_items.item_id = ?) AND SummariesDate = ?",item_id,item_id,formatted_date)
			end
		end

		def self.by_id news_item_id
			select("summary_items.id,summary_id,summaries.title,strftime('%Y-%m-%d',summaries.date) as 'SummariesDate'")
			.joins("LEFT JOIN summaries ON summaries.id = summary_items.summary_id")
			.where("summaries_items.id = ?",news_item_id)
		end

		def self.items_by_summary summary_id,exclude_id=nil
			items_sql = "items.name,items.wd_descr,items.wiki_text,items.fame,items.relevance,"
			unless exclude_id.nil?
				select("#{items_sql}items.name as item_name,summary_items.id,summary_items.item_id")
				.joins("LEFT JOIN items ON items.id = summary_items.item_id")
				.where("summary_id = ? AND NOT item_id = ? AND item_id > 0",summary_id,exclude_id)
			else
				select("#{items_sql}items.name as item_name,summary_items.id,summary_items.item_id")
				.joins("LEFT JOIN items ON items.id = summary_items.item_id")
				.where("summary_id = ? AND summary_items.item_id > 0",summary_id)
			end
		end

	end
end