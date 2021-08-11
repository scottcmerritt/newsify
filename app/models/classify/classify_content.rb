module Classify
module ClassifyContent
	# methods for classifying item content, wiki_text, etc...
 extend ActiveSupport::Concern

def topics min_salience: 0.0 #05
	Newsify::ContentTopic.where(content_type:self.class.name,content_id:self.id)
	.where("score > ?",min_salience)
	.order("score DESC")
end
def tag_count
	Newsify::SourceTopic.where(item_id:self.id).count
end

def google_classify! entities: false, min_salience: 0.0, ga: nil, exclude_item_ids: nil
		ga = GoogleAnalyze.new if ga.nil?
    	#@sentiment = ga.sentiment_from_text text_content: "I just ate a delicious meal at a restaurant"
    	begin
    		if self.to_classify.scan(/\w+/).size >= 20
		    	@classified = ga.classify_from_text text_content: self.to_classify
		    	@classified.each do |row|
		      		self.add_google_category row[:name], row[:confidence]
		#      {:name=>"/News/Politics", :confidence=>0.9399999976158142}
		    	end
	    	end
    	rescue Exception => e

    	end
    	if entities
	    	self.google_get_entities! min_salience: min_salience, ga: ga , exclude_item_ids: exclude_item_ids
	    else
	    	return @classified
	    end
	end

	def google_get_entities! min_salience: 0.0, ga: nil, exclude_item_ids: nil
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
      self.add_entity_rows rows: rows, min_salience: min_salience, exclude_item_ids: exclude_item_ids
      rescue Exception => e

      end
      rows
	end

	def to_classify
		if self.is_a?(Newsify::Item)
			"#{self.title} #{(self.wiki_text.blank? ? "" : self.wiki_text)}"
		elsif self.is_a?(Newsify::Content)
			"#{self.title} #{(self.article.blank? ? "" : self.article)}"
		elsif self.is_a?(Newsify::Source)
			"#{self.title} #{(self.description.blank? ? "" : self.description)}"
		end
	end

	def add_google_category label, score, category = true, add_category: true
		classifier = Newsify::ContentTopic::CLASSIFIERS.find_index("Google:classify")
		item = Newsify::Item.by_google_category label
		item = Newsify::Item.create_google_category label if item.nil? && add_category

		# if add_category == false, ONLY creates a ContentTopic row if category doesn't exist AND google CATEGORY already exists



		if self.is_a?(Newsify::Content)
			Newsify::ContentTopic.create(content_type:self.class.name,content_id: self.id,item_id:item.id,score:score,classifier:classifier,category:category) unless item.nil? || ContentTopic.where(content_type:self.class.name,content_id: self.id,item_id:item.id).exists?
		else
			Newsify::SourceTopic.create(content_type:self.class.name,content_id: self.id,item_id:item.id,score:score,classifier:classifier,category:category) unless item.nil? || SourceTopic.where(content_type:self.class.name,content_id: self.id,item_id:item.id).exists?
		end
	end
	def add_entity_rows rows:, min_salience: 0.3, exclude_item_ids: nil
		ignore_itypes = ["NUMBER"]
		classifier = Newsify::ContentTopic::CLASSIFIERS.find_index("Google:entities")
		item_keys = {}
		rows.each do |row|
			item = nil
			item_key = "#{row.name.downcase}#{row.type}#{row.wiki_url}"
			unless row.wiki_url.blank?
				item = Newsify::Item.where(wiki_url: row.wiki_url).first
				item.update(itype: row.type) if !item.nil? && item.itype.blank?

				item = Newsify::Item.create(name:row.name,itype:row.type,wiki_url:row.wiki_url) if item.nil?
			else
				item = Newsify::Item.where("LOWER(name) = ? AND itype = ?",row.name.downcase,row.type).first
				item = Newsify::Item.create(name:row.name,itype:row.type,wiki_url:row.wiki_url) if item.nil? && !ignore_itypes.include?(row.type) && row.salience >= min_salience
			end
			Newsify::ContentTopic.create(content_type:self.class.name,content_id: self.id,item_id:item.id,score:row.salience,classifier:classifier) if !item.nil? && (exclude_item_ids.nil? || !exclude_item_ids.include?(item.id)) && !ContentTopic.where(content_type:self.class.name,content_id: self.id,item_id:item.id).exists?
		end
	end

end
end