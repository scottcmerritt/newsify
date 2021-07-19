module Newsify
	class ContentTopic < TopicAdder
		self.table_name = "content_topics"

		def item
			Item.find_by(id:self.item_id)
		end
		
		def self.add type, id, item_id, user_id, score=nil, approved = false, category = false
			
			if type.nil? || id.nil? || item_id.nil?
				return false
			end

			if (ContentTopic.exists?(:content_type=>type,:content_id => id,:item_id => item_id))
				
				update_count = 0
				
				cts = ContentTopic.where("content_type = ? AND content_id=? AND item_id=?",type,id,item_id)
				cts.each do |ct|
					if (ct.approved == false || ct.approved.nil?) && approved == true
						ct.approved = true
						ct.approvedby = user_id
						ct.approved_at = DateTime.now
					end
					ct.category = category
					if !score.nil?
						ct.score  = score
					end
					if ct.changed? && ct.save
						update_count+=1
					else
						
					end
				end

				return {:updated=>update_count}
			else
				st = ContentTopic.new(:content_type=>type,:content_id=>id,:item_id=>item_id,:createdby=>user_id,:score=>score,:cateogry=>category)
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

	end
end