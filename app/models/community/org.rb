module Community
	class Org < ActiveRecord::Base
		def self.model_name
      		ActiveModel::Name.new("Community::Org", nil, "Org")
    	end

    	include Membership
#		include IconUtil, VoteCacheable, Membership
#		include HasBadge
#		has_merit
		has_many :author_orgs, class_name: "Newsify::AuthorOrg"
		has_many :org_users
		has_many :sources, class_name: "Newsify::Source"
		belongs_to :item, optional: true, class_name: "Newsify::Item"


		attribute :applicant
		attribute :applicant_relationship

		attribute :is_seller

		def round_to_half num
		    (num * 2.0).round / 2.0
		end
		def round_to_quarter num
		    (num * 4.0).round / 4.0
		end

		def checked_in?(user)
			Surge::SurgeVisitor.exists?(org_id:self.id,user_id:user.id,active:true)
		end
		def checked_in
			Surge::SurgeVisitor.select("users.username,surge_visitors.*")
			.joins("LEFT JOIN users ON users.id = surge_visitors.user_id")
			.where(org_id:self.id,active:true)
		end
		def check_in!(user,visit_id=nil)
			Surge::SurgeVisitor.create(org_id:self.id,user_id:user.id,surge_visit_id:visit_id)
		end
		def check_out!(user)
			Surge::SurgeVisitor.where(org_id:self.id,user_id:user.id,active:true).update(active:false)
		end

		def auto_discount!
			cnt = self.checked_in.length #self.customer_count
			discount_pct = (cnt <= self.surge_capacity) ? cnt/self.surge_capacity.to_f : 1.0
			self.apply_discount!(discount_pct)

		end

		#TODO: add rounding to .25 or .5
		def apply_discount! discount_pct, round_num = true
			self.surge_menus.each do |menu|
				menu.menu_items.each do |surge_menu_item|
					adj_price = surge_menu_item.target_price*discount_pct unless surge_menu_item.target_price.nil?
					if round_num
						adj_price = round_to_half adj_price
					end
					adj_price = surge_menu_item.cost if adj_price < surge_menu_item.cost
					surge_menu_item.current_price = adj_price
					
					surge_menu_item.save
				end
			end
		end

		def customer_count
			#Surge::SurgeVisit.where(org_id:self.id,active:true).sum{|visit| visit.party_size}
			Surge::SurgeVisitor.where(org_id:self.id,active:true).count
		end

		def total_owed visitor
			total = 0
			self.surge_bills(visitor).each do |bill|
				total+=bill.total_paid
			end
			return total
		end

		def surge_menus
			#Surge::SurgeItem.where(itype:"SURGE_MENU",parent_id:self.item_id)
			Surge::SurgeMenu.where(itype:"SURGE_MENU",parent_id:self.item_id)
		end

		def total_surge_items
			# ADDED this so it can be cached more efficiently then pulling the surge_items into memory and counting them
			surge_items.length
		end
		def surge_items
			#TODO: add caching (by timestamp, to honor PUBLISHED prices)
			items = {}
			self.surge_menus.each do |menu|
				menu.menu_items.each do |surge_menu_item|
					items[surge_menu_item.id] = surge_menu_item
				end
			end
			return items
		end
		
		def surge_bills(user=nil)
			if user.nil?
				Surge::SurgeBill.where("surge_bills.org_id = ? AND NOT surge_bills.is_paid = ? ",self.id,true)
			else
				Surge::SurgeBill.joins("LEFT JOIN surge_bill_users ON surge_bill_users.surge_bill_id = surge_bills.id")
				.where("surge_bills.org_id = ? AND (surge_bills.user_id = ? OR surge_bill_users.user_id = ?) AND NOT surge_bills.is_paid = ? ",self.id,user.id,user.id,true)
			end
			#Surge::SurgeBillUser.
		end
		
		def current_surge_discount
			return 1.0
		end

		def add_surge_bill(user)
			Surge::SurgeBill.create(org_id:self.id,user_id:user.id,discount_current:self.current_surge_discount)
		end

		def has_surge_item? surge_item_id
			return self.surge_items.key?(surge_item_id)
		end

		# NOTE: bill likely needs to be refreshed to include the purchase
		def add_surge_purchase(user,surge_item_id,quantity,bill=nil)
			if has_surge_item? surge_item_id
				if bill.nil?
					bill = self.add_surge_bill(user)
				end
				surge_item = self.surge_items[surge_item_id]
				purchase = bill.add_surge_purchase(user,surge_item,quantity)
				return bill, purchase
			else
				return nil, nil
			end			
		end

		#scope :my_groups, -> {joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")}
		def item
			Newsify::Item.find_by(id:self.item_id)
		end

		def room_org room_id
			RoomOrg.where(org_id:self.id,room_id:room_id).first
		end
		def rooms
			return nil if !defined?(Room)
			@rooms = Room.joins("LEFT JOIN room_orgs ON rooms.id = room_orgs.room_id")
			.where("room_orgs.org_id = ?",self.id)
		end

		def broadcast_approval user
			#locals = {:org=>@org}#			
			#notification = render_to_string(:partial=>"community/orgs/notice/added",:locals=>locals,:layout=>false)
			notification = "<div>Test notice</div>"
			NotificationChannel.broadcast_to user, {:notification=>notification,:org_id=>self.id}
		end

		def surge_enabled?
			if defined?(Surge::SurgeOrg)
				surge_org = Surge::SurgeOrg.find_by(org_id:self.id)
				return !surge_org.nil? && surge_org.is_active
			else
				false
			end
		end

	#	before_save :configure_approval_types

		def clear_users!
			Community::OrgUser.where("org_id = ?",self.id).destroy_all
		end

		def can_edit? user
			self.createdby == user.id
		end

		def joinable?
			self.is_group
		end

		def cache_content_scores!
			
			self.cached_content_interesting_up = self.interesting_votes(vote_flag: true).count
			self.cached_content_interesting_down = self.interesting_votes(vote_flag: false).count
			self.cached_content_votes_total = self.interesting_votes(vote_flag: nil).count
			
			self.cached_content_score = calc_content_score minimum_votes: 30, total_votes: self.cached_content_votes_total

			self.vote_cache.save
			#TODO: add 
			# cached_content_votes_total
			# cached_content_voters_total
		end

		def calc_content_score minimum_votes: 30, total_votes: nil, votable_type:"Source"
			total_votes = self.cached_content_votes_total if total_votes.nil?
			if total_votes == 0
				0
			else
				ratio = (total_votes-minimum_votes)/minimum_votes
				sigmoid_adjusted = Math.exp(ratio) / (Math.exp(ratio) + 1) * self.interesting_vote_pct
				if total_votes < minimum_votes*0.1
					0.05 * sigmoid_adjusted
				elsif total_votes < minimum_votes*0.2
					0.2 * sigmoid_adjusted
				elsif total_votes < minimum_votes*0.5
					0.5 * sigmoid_adjusted
				elsif total_votes < minimum_votes
					0.5 * sigmoid_adjusted
				elsif total_votes < (minimum_votes * 2)
					0.75 * sigmoid_adjusted
				else
					sigmoid_adjusted
				end
			end
		end

		def custom_vote_count votable_type: "Source", vote_flag: true, vote_scope: "interesting"
			return nil if !defined?(ActsAsVotable)

			data = ActsAsVotable::Vote.where("votable_type = ? AND votable_id IN (?) AND vote_scope = ?",votable_type,self.sources.pluck(:id),vote_scope)
			data = data.where("vote_flag = ?",vote_flag) unless vote_flag.nil?
			data
		end
		def interesting_votes votable_type:"Source", vote_flag: true,vote_scope: "interesting"
			custom_vote_count votable_type: votable_type, vote_flag: vote_flag, vote_scope: vote_scope
		end
		def interesting_vote_pct votable_type = "Source"
			up = self.interesting_votes({votable_type: votable_type,vote_flag: true}).count
			down = self.interesting_votes({votable_type: votable_type,vote_flag: false}).count
			res = (up.to_f / (up + down) *100)
			res = res == 0 ? 0 : res > 5 ? res.round(0) : res.round(1)
		end

		def self.lookup_or_create news_item, createdby, lookup_only = false
			
			uid = (news_item["source"]["id"].nil? || news_item["source"]["id"] == "null") ? news_item["source"]["name"].downcase : news_item["source"]["id"]
			org = Org.select("orgs.id").where("newsapi_key = ?",uid).first
			if org.nil?
				if lookup_only
					return nil
				else
					org = Org.new(:name=>news_item["source"]["name"],:newsapi_key=>uid,:is_news=>1,:createdby=>createdby)
					if org.save
						return org.id
					else
						return nil
					end
				end
			else
				return org.id
			end
		end

		def authors
			return Author.select("authors.*")
			.joins("LEFT JOIN author_orgs ON author_orgs.author_id = authors.id")
			.where("org_id = ?",self.id)
		end

		def members
			return User.select("users.*,org_users.is_active")
			.joins("LEFT JOIN org_users ON org_users.user_id = users.id")
			.where("org_id = ? AND org_users.removed = ? AND approved = ?",self.id,false,true)
		end
		def pending_members
			return User.select("users.*,org_users.is_active")
			.joins("LEFT JOIN org_users ON org_users.user_id = users.id")
			.where("org_id = ? AND org_users.is_pending = ?",self.id,true)
		end
		def pending_member_count
			return User.joins("LEFT JOIN org_users ON org_users.user_id = users.id")
			.where("org_id = ? AND org_users.is_pending = ?",self.id,true).count
		end
		def former_members
			return User.select("users.*,org_users.is_active")
			.joins("LEFT JOIN org_users ON org_users.user_id = users.id")
			.where("org_id = ? AND org_users.removed = ?",self.id,true)
		end

		def member_count
			#TODO: cache this
			User.joins("LEFT JOIN org_users ON org_users.user_id = users.id")
			.where("org_id = ? AND org_users.removed = ? AND org_users.approved = ?",self.id,false,true).count
		end
		
		
	end
end