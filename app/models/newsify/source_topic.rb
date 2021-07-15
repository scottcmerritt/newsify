module Newsify
class SourceTopic < TopicAdder
	self.table_name = "source_topics"

	belongs_to :item, inverse_of: :source_topics

	# classifier: 0 = Google, 1 = AWS:Comprehend, 2 = Aylien
	# itype_id: 0 = PERSON, 1 = ORGANIZATION, 2 = LOCATION, OTHER

	# score should be blend of certainty and salience (for now it is salience)

	#TODO: consider adding confidence and salience?
	# confidence should be confidence of association
	# salience should be importance to the source

	def parent
		self.item.parent unless self.item.nil?
	end
	
	def self.remove source_id, item_id, user_id, score=nil, approved = false
		if !source_id.nil? && !item_id.nil?
			SourceTopic.where("source_id=? AND item_id=?",source_id,item_id).destroy_all
		end
	end
	
	def self.add source_id, item_id, user_id, score=nil, approved = false
		
		if source_id.nil? || item_id.nil?
			return false
		end

		if (SourceTopic.exists?(:source_id => source_id,:item_id => item_id))
			
			update_count = 0
			
			sts = SourceTopic.where("source_id=? AND item_id=?",source_id,item_id)
			sts.each do |st|
				if (st.approved == false || st.approved.nil?) && approved == true
					st.approved = true
					st.approvedby = user_id
					st.approved_at = DateTime.now
				end
				if !score.nil?
					st.score  = score
				end
				if st.changed? && st.save
					update_count+=1
				else
					
				end
			end

			return {:updated=>update_count}
		else
			st = SourceTopic.new(:source_id =>source_id,:item_id=>item_id,:createdby=>user_id,:score=>score)
			if approved
				st.approved = true
				st.approvedby = user_id
				st.approved_at = DateTime.now
			else
				st.approved = false
			end
			if st.save
				return true
			else
				return false
			end
		end

	end

	# gets ALL tags (so total snippets about an item)
	def self.item_tagged_source_count item_id, use_cache=true, refresh=false, cache_expiration=60000
		if use_cache
			return Cache.item_tagged_source_count item_id,refresh,cache_expiration
		else
			return SourceTopic.joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
			.where("item_id=? AND sources.is_duplicate = ?",item_id,false).count
		end
	end

	def self.item_scored_tagged_source_count item_id, use_cache=false, refresh=false, cache_expiration=60000
		if false && use_cache
			#return Cache.item_tagged_source_count item_id,refresh,cache_expiration
		else
			return SourceTopic.joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
			.where("item_id=? AND score > ? AND sources.is_duplicate = ?",item_id,0,false).count
		end
	end

	def self.item_approved_tagged_source_count item_id, use_cache=false, refresh=false, cache_expiration=60000
		if false && use_cache
			#return Cache.item_tagged_source_count item_id,refresh,cache_expiration
		else
			return SourceTopic.joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
			.where("item_id=? AND source_topics.approved = ? AND sources.is_duplicate = ?",item_id,true,false).count
		end
	end

	def self.item_tagged_source_count_by_users item_id, user_ids = []
		if !user_ids.is_a?(Array)
			user_ids = [user_ids]
		end
			
		return SourceTopic.joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
			.where("item_id=? AND NOT sources.is_duplicate = ? AND source_topics.approved = ? AND (source_topics.createdby IN (?) OR source_topics.approvedby IN (?))",item_id,true,true,user_ids,user_ids).count
	end

	def self.topic_approved item_id, limit=1000
		SourceTopic.select("sources.*").joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
		.where("item_id=? AND source_topics.approved = ? AND sources.is_duplicate = ?",item_id,true,false)
		.limit(limit)
	end
	

	def self.most_tagged_count
		data = SourceTopic.select("items.name,items.id as item_id,COUNT(source_topics.id) as tag_count")
			.joins("LEFT JOIN sources ON sources.id = source_topics.source_id")
			.joins("LEFT JOIN items ON items.id = source_topics.item_id")
		    .group("items.name,items.id")
		    .where("sources.is_duplicate=?",false)
		    .order("tag_count DESC")
		    .limit(1)
		    if data.nil? || data.length == 0
		    	return 0
		    else
				return data[0].tag_count
			end
	end
end
end