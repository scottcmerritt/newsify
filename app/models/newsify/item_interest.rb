module Newsify
	class ItemInterest < ActiveRecord::Base # < AbstractModel
		self.table_name = "item_interests"

		def item_name
			item = Item.find_by(id:self.item_id)
			item.name unless item.nil?
		end
		def item
			item = Item.find_by(id:self.item_id)
		end
		def parent
			self.item.parent unless self.item.parent.nil?
		end

		# calculates the interests, if remove, then it removes the OLDER ItemInterest rows
		def self.calc_interests! user, resource_type: Newsify::Source, upvotes: true, downvotes: true, remove: false, limit: 3000
			# one approach might be to maintain a list of global relevance/fame
			# if an item is low "score" but high relevance/fame, include it in interests, otherwise exclude it?

			upvote_weight = 15.0
			downvote_weight = -5.0

			#current_time = 2.minutes.ago
			recent_row = ItemInterest.where(resource_type:resource_type.to_s,user_id:user.id).order("id DESC").first
			max_id = recent_row.id unless recent_row.nil?

			if upvotes
				user.find_up_votes_for_class(resource_type, {vote_scope:"interesting"}).limit(limit).each do |vote|
					vote.votable.all_topics.each do |item|
						value = item.score*upvote_weight
						ItemInterest.create(item_id:item.id,user_id:user.id,value:value,created_at:vote.updated_at,resource_type:resource_type,resource_id:vote.votable.id)
						ItemInterest.create(item_id:item.parent.id,user_id:user.id,value:(value*0.5),created_at:vote.updated_at,resource_type:resource_type,resource_id:vote.votable.id) unless item.parent.nil?
					end
				end
			end

			if downvotes
				user.find_down_votes_for_class(resource_type, {vote_scope:"interesting"}).limit(limit).each do |vote|
					vote.votable.all_topics.each do |item|
						value = item.score*downvote_weight
						ItemInterest.create(item_id:item.id,user_id:user.id,value:value,created_at:vote.updated_at,resource_type:resource_type,resource_id:vote.votable.id)
						ItemInterest.create(item_id:item.parent.id,user_id:user.id,value:(value*0.5),created_at:vote.updated_at,resource_type:resource_type,resource_id:vote.votable.id) unless item.parent.nil?
					end
				end
			end
			#ItemInterest.where(resource_type:resource_type.to_s,user_id:user.id).where("created_at < ?",current_time).destroy_all if remove
			ItemInterest.where(resource_type:resource_type.to_s,user_id:user.id).where("id <= ?",max_id).delete_all if remove && !max_id.nil?
		end

		def self.by_user user, limit: 500, as_hash: false, order: :desc, query: nil
			# similarly to calc_interests! maybe filter out low relevance/fame items 
			#(since filler words are not that helpful

			data = ItemInterest.select("item_id,items.name,items.itype,items.wiki_url,SUM(value*items.relevance) as interests,max(item_interests.created_at) as created_at,max(item_interests.updated_at) as updated_at")
			.joins("LEFT JOIN items ON items.id = item_id")
			.where(user_id:user.id)
			.group("items.name,item_id,items.itype,items.wiki_url")

			data = order == :desc ? data.order("interests DESC") : data.order("interests ASC")
			
			data = data.where("LOWER(name) = ?",query.downcase) unless query.nil?
			

			data = data.limit(limit)

			if as_hash
				result = {}
				data.each do |row|
					result[row.item_id] = row.interests
				end
				return result

			else
				return data
			end

		end

	end

end