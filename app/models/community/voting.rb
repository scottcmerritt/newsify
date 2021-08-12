module Community
	
	class Voting
		VOTESCOPE_INTERESTING = "interesting"
		VOTESCOPES = ["quality","interesting","learnedfrom","fun","funny"] # was learned_something
		VOTESCOPES_ALG = ["rank","priority","fame","relevance"]

		VOTESCOPES_MODERATE_SLIM = ["spam","ad"]
		VOTESCOPES_MODERATE = ["spam","ad","clickbait","english"]
		VOTESCOPES_EXTRA = ["attracted","intrigued"]

		VOTESCOPE_LABELS = {"learnedfrom" => "Learned","clickbait"=>"Click bait"}
		
		def initialize params: params = {}, user: nil, is_admin:false,logger: nil, show_count: true
			@params = params
			@user = user
			@logger = logger
			@is_admin = is_admin

			@show_count = show_count

		#	@vote_target
		#	@vote_scope
		#	@icon_colors
		#	@label

			@label = params[:label]

			@vote_weight = 10

			@vote_type = params[:vtype] == "remove" ? "remove" : (params[:vtype] == "down" ? "bad" : "like")
			@vote_scope = params[:vscope].downcase if params[:vscope] && Community::Voting.votescopes_all.include?(params[:vscope].downcase)
			
			@vote_ui = params[:vui] && ["toggle","engage"].include?(params[:vui]) ? params[:vui] : nil

			setup_vote_target

		end
		def is_admin?
			@is_admin
		end
		def current_user
			@user
		end
		def logger
			@logger
		end

		def params
			@params
		end
		def vote_ui
			@vote_ui
		end
		def vote_target
			@vote_target
		end
		def vote_scope
			@vote_scope
		end

		def upvote_render_params
			{user:current_user,object:@vote_target,no_wrap:true,vote_scope:@vote_scope,labels:Community::Voting::VOTESCOPE_LABELS,icons:@icons,icon_colors:@icon_colors,label:@label}
		end
		def updown_render_params
			{user:current_user,object:@vote_target,no_wrap:true,vote_scope:@vote_scope,labels:Community::Voting::VOTESCOPE_LABELS,icons:@icons,icon_colors:@icon_colors,label:@label,show_count_breakdown:@show_count}
		end


		def self.votescopes
			VOTESCOPES + VOTESCOPES_MODERATE
		end
		def self.votescopes_all
			VOTESCOPES + VOTESCOPES_ALG + VOTESCOPES_MODERATE + VOTESCOPES_EXTRA
		end
		def self.votescopes_main
			VOTESCOPES
		end
		def self.votescopes_moderation
			VOTESCOPES_MODERATE
		end
		def log_vote!
			current_user.auditable
			

			@icons = @vote_scope == "interesting" ? {up: "check-circle",down:"ban"} : nil
			@icon_colors = ["text-success","text-secondary"]
			# optionally add vote_scope, :vote_scope => 'rank', :vote_scope => 'spam'

			logger.debug "OTYPE: #{params[:otype]}, #{params[:oid]}"
			#@vote_target = Community::Preview.get(params[:otype],params[:oid],is_admin?)
			
			

			process_vote_audit if @vote_target.is_a? Community::VoteAudit
			process_user_conversation if defined?(UserConversation) && @vote_target.is_a?(UserConversation)
			process_suggest_game if defined?(SuggestGame) && @vote_target.is_a?(SuggestGame)
			
			#TODO: consider propagating to the creator of the content as well?
			#TODO: consider propagating to other's who labeled it the same
			vote_up = ["remove","down","bad"].include?(@vote_type) ? false : true
			add_points = vote_up ? !current_user.voted_up_on?(@vote_target,{vote_scope:@vote_scope}) : !current_user.voted_down_on?(@vote_target,{vote_scope:@vote_scope})

			process_vote

			process_room_message(vote_up,add_points) if defined?(RoomMessage) && @vote_target.is_a?(RoomMessage)

			if current_user.respond_to?(:add_points)
				current_user.add_points(1, category: 'equity-eligible')
				current_user.badge_adder(add: badge_name)
			end

			
		end
		private

		def setup_vote_target
			if (params[:otype] == "vote")
				@vote_target = Community::VoteAudit.where(:vote_id=>params[:oid].to_i).first_or_create
			elsif (params[:otype] == "vote_audit")
				#@vote_target = Community::VoteAudit.where(vote_id: @vote_target.id).first_or_create
				@vote_target = Community::VoteAudit.find_by(id: params[:oid].to_i)
			elsif (params[:otype] == "user_conversation")
				@vote_target = UserConversation.find_by(id: params[:oid].to_i)
			elsif (params[:otype] == "suggest_game")
				@vote_target = SuggestGame.find_by(id: params[:oid]) #game_id])
			else
				@vote_target = Community::Preview.get(params[:otype],params[:oid],is_admin?)
			end
		end

		def process_vote
			if @vote_type == "remove"
				vote_params = {:vote_scope => @vote_scope}
				@vote_target.unvote_by(current_user, vote_params) #, :vote => vote_type
				@chained_target.auditable.unvote_by(@vote_target, vote_params) if @chained_target.class.name == "User" #@chained_target.is_a?(User)
				
				@vote_target.similar.each {|similar_target| similar_target.unvote_by(current_user,{}) } if @vote_target.respond_to?(:similar) && !@vote_target.similar.nil?
				GuessScope.log_vote! target:@vote_target, user:current_user, scope: @vote_scope, value: false
			else
				vote_params = {:voter => current_user, :vote => @vote_type, :vote_scope => @vote_scope, :vote_weight=> @vote_weight}
				@vote_target.vote_by vote_params
				@chained_target.auditable.vote_by(:voter => @vote_target, :vote => @vote_type, :vote_scope => @vote_scope, :vote_weight=> @vote_weight) if @chained_target.class.name == "User" #@chained_target.is_a?(User)
				
				# applies the vote to similar items
				@vote_target.similar.each {|similar_target| similar_target.vote_by vote_params} if @vote_target.respond_to?(:similar) && !@vote_target.similar.nil?

				GuessScope.log_vote! target:@vote_target, user:current_user, scope: @vote_scope, value: true
			end

			log_rated_room! if defined?(UserConversation) && @vote_target.is_a?(UserConversation)
		end


		def process_vote_audit
			# added propagation to the user_audit object
			
			logger.debug "CHANGED VOTEAUDIT"
			voter = @vote_target.vote.voter
			@chained_target = voter if (!voter.nil? && (voter != current_user))
			logger.debug @chained_target.as_json
			logger.debug "IS A USER" if voter.is_a?(User)
			logger.debug "AFTER"
		end

		def process_user_conversation
			@chained_target = @vote_target.user if (!@vote_target.user.nil? && (@vote_target.user != current_user))
		end

		def process_suggest_game
			@chained_target = @vote_target.user if (!@vote_target.user.nil? && (@vote_target.user != current_user))
		end

		def process_room_message vote_up, add_points = false
			vote_counts = {up:@vote_target.get_up_votes(vote_scope:@vote_scope).count , down:@vote_target.get_down_votes(vote_scope:@vote_scope).count}
			
			
			

			msg_points = vote_up ? 1 : -1
			if current_user != @vote_target.user
				@vote_target.user.badge_adder(add: sender_badge_name)
				@vote_target.room.badge_adder(add: sender_badge_name)
				custom_result = {}

				
			
				case @vote_scope
				when "interesting"
					custom_result = {vote: {message: @vote_target.id,voter:current_user.id,counts: vote_counts}}
					
					if add_points
						@vote_target.room.add_points(msg_points,category:"interesting")
						#NOTE: we are doing room_org rather than org
						@vote_target.room.org_by_user(@vote_target.user).add_points(msg_points,category:"interesting") if @vote_target.room.org_by_user(@vote_target.user)
						#TODO: do we want to do room_user? (maybe instead of user?)
						@vote_target.user.add_points(msg_points,category:"content-interesting")
						@vote_target.user.add_points(msg_points,category:"equity-eligible")
					end
					

					custom_result[:teamScores] = new_room_scores #{update:true}
					#custom_result[:teamScores] = "<div>Testing</div>"
					#custom_result[:teamScores] = render_to_string(:partial=>"rooms/parts/teams_header",:locals=>{:room=>@vote_target.room},:layout=>false)

				when "spam"
					if add_points
						@vote_target.room.add_points(msg_points,category:@vote_scope)
						@vote_target.user.add_points(msg_points,category:@vote_scope)
						@vote_target.room.org_by_user(@vote_target.user).add_points(msg_points,category:@vote_scope) if @vote_target.room.org_by_user(@vote_target.user)
					end
				end
			
				RoomChannel.broadcast_to @vote_target.room, custom_result if add_points && defined?(RoomChannel)
			end
		end

		def sender_badge_name
			case @vote_scope
			when "spam","ad"
				"spammer"
			else
				"reviewed"
			end
		end
		def badge_name
			case @vote_scope
			when "interesting"
				"reviewer-interest"
			when "quality"
				"reviewer-quality"
			else
				"reviewer"
			end
		end

		def new_room_scores
			new_scores = []
			@vote_target.room.teams.each do |org|
				room_org = org.room_org(@vote_target.room.id)
				new_scores.push({roomOrgId:room_org.id,score:room_org.points(category:"interesting").to_i})
			end
			new_scores
		end

		def log_rated_room!
			return nil if !defined?(RatedRoom)
			RatedRoom.create(room_id:@vote_target.room_id,user_id:current_user.id) unless RatedRoom.where(room_id:@vote_target.room_id,user_id:current_user.id).exists?
		end

	end
end