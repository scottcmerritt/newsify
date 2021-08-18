module Community
	class Preview
		# include Ui #::UiTab

		MAIN_CONTENT = [Newsify::Item,Newsify::Source,Newsify::Summary,User,Org,Newsify::Author] #Room
		EXTRA_CONTENT = [ActsAsVotable::Vote] #,Content,RoomMessage]
		RELATIONSHIP_CONTENT = [] #SummarySource,SummaryItem,SourceTopic,OrgUser,AuthorOrg]
		MODERATION_CONTENT = [] #SummaryItemsRemoved,SourceTopicsRemoved]

		#attr_accessor :otype, :oid
		def initialize params = {}
			@otype = params[:otype]
			@oid = params[:oid]
			@data = nil

			@view_log = params[:view_log]

			@vote = params[:vote]
		end

		def self.content_info
			info = [
				{
					name: "Objects", count: Community::Preview.main_content_count
				},
				{
					name: "Pieces of data", count: Community::Preview.key_data_count
				},
				{
					name: "Most data", count: Community::Preview.total_content_count
				},
				{
					name: "Total data", count: Community::Preview.actual_content_count
				},
				{
					name: "Changed data", count: Community::Preview.moderation_changes_count
				}
			]

			return info.map{|row| Ui::UiTab.new({name: row[:name],count:row[:count]}) }
		end

		def self.main_content_count
			MAIN_CONTENT.sum{|klass| klass.count}
		end

		def self.key_data_count
			EXTRA_CONTENT.sum{|klass| klass.count}
		end
		# votes, machine summaries, room messages, 
		def self.total_content_count
			Preview.main_content_count + Preview.key_data_count
		end

		def self.actual_content_count
			# add in audits on top of audits
			# relationships between tags, content, etc...
			Preview.total_content_count + RELATIONSHIP_CONTENT.sum{|klass| klass.count}
		end

		def self.moderation_changes_count
			MODERATION_CONTENT.sum{|klass| klass.count}
		end

		def otype_guessed
			return self.otype unless self.otype.nil?
			self.data.otype_guessed unless self.data.nil?
		end
		def icon_guessed
			self.data.icon_guessed unless self.data.nil?
		end
		def otype
			@otype
		end
		def id
			self.oid
		end
		def oid
			@oid
		end

		def setup
			if self.otype=="item"
		      @data = Newsify::Item.select("id,name,name as title,wiki_text,wiki_img_url as thumb,wiki_img_url as image,created_at,updated_at,itype,url,sash_id,parent_id").where("id =?", self.oid).first # find_by(id: params[:oid]) 
		      #object = preview #.to_json # as_json({})
		    elsif self.otype == "person"

		    elsif self.otype == "summary"
		    	@data = Summary.select("id,title,created_at,updated_at").where("id = ?",self.oid).first # find_by(id: params[:oid])
		    else
		    	@data = Community::Preview.get(self.otype,self.oid)		      
		      #object = preview
		    end
		end
		def get_vote_audit 
			Community::VoteAudit.where(vote_id: @vote.id).first_or_create
		end
		def vote
			@vote
		end
		def data
			setup
			@data
		end
		def setup?
			!self.data.nil?
		end

		def title
			self.data.title unless self.data.nil?
		end
		def content
			self.data.wiki_text unless self.data.nil? || !self.data.respond_to?(:wiki_text)
		end
		def created_at
			self.data.created_at
		end

		def self.get otype, oid, is_admin = false
			otype = otype.downcase unless otype.nil?
			scope_all = Preview.get_otype(otype) if (is_admin || Preview.scoped_whitelist.include?(otype))
			res = nil
			unless scope_all.nil?
				res = scope_all.where("id = ?",oid).first
			end
			return res
		end
		
		def self.my_recent user, otype="Item", limit=30
			Community::Preview.get_otype(otype, user)
			.where("created_by = ?",user.id).order("created_at DESC")
			.limit(limit)
		end

		def self.get_otype otype, user = nil
			otype = otype.downcase unless otype.nil?

			case otype
			when "item"
				output = Newsify::Item.all
			when "summary" # || "news")
				output = Newsify::Summary.all
			when "source" # || "news")
				output = Newsify::Source.all
			when "sound" #("audio" || "sound")
				output = Newsify::Item.all_sounds
			when "person" #("audio" || "sound")
				output = Newsify::Item.all_people
			when "source"
				output = Newsify::Source.all
			when "vote"
				output = ActsAsVotable::Vote.all
			when "vote_audit"
				output = Community::VoteAudit.all
			when "room_message"
				output = RoomMessage.all
			when "room"
				output = Room.all
			when "user"
				output = User.all
			when "version"
				output = PaperTrail::Version.all
			else
				nil
			end
			return output
		end
		
		def self.scoped_whitelist
			["item","summary","source","sound","person","source","room","room_message","user"]
		end

		def self.by_room room_id, otype = nil
			previews = RoomPreview.where(room_id:room_id).order("pinned")

			res = []
			previews.each do |room_preview|
				res.push Preview.get(room_preview.preview_type, room_preview.preview_id)
			end
			res
		end

		def self.by_otype otype = nil, user = nil, limit = 40
			otype = otype.downcase unless otype.nil?
			scope_all = Preview.get_otype(otype) if Preview.scoped_whitelist.include?(otype)

			case otype
			when "item"
				output = scope_all.where.not(itype: "SOUND")
			when "summary","source","sound","person","room","room_message" # || "news")
				output = scope_all
			else
				otypes = ["item","summary","sound"] #{}"news","audio"]
				#TODO: add weighting

				res = []
				otypes.each do |_otype|
					res = res + Preview.by_otype(_otype, user, limit)
				end
				output = res.sample(limit)
			end

			output = output.is_a?(Array) ? output.first(limit) : output.limit(limit)

			return output
		end
		
	end
end