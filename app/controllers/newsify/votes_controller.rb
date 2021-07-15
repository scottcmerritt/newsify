module Newsify
class VotesController < ApplicationController
	#before_action :custom_authenticate_user!
	before_action :authenticate_user!
	skip_before_action :verify_authenticity_token, only: [:vote], if: :json_request?

	def self.controller_path
      "community/votes" # change path from app/views/ideas to app/views/tasks
  	end

	def index
		@vote_scopes = Community::Voting.votescopes_all
		#Community::VoteAudit.first.vote_by(current_user)
		#Room.all.last.vote_by(current_user)
		#@room = Room.all.last
		#@room.vote_by({:voter=>current_user,:vote=>"like"})
		
	end

	def audits
		#Community::VoteAudit.find_each(&:update_cached_votes)
		if params[:users]

			@vote_audits = Community::UserAudit.where.not("user_id is NULL")
		else			
			@vote_audits = Community::VoteAudit.all
		end
	end
=begin
	# GET /testaudit
	def test_audit

		@test_user = User.find(13)
		#149 is the vote_audit for an item by User 30, or id:13
		@vote_audit_id = 149
		@vote_target = Community::VoteAudit.find_by(id: @vote_audit_id)
		if @vote_target.is_a? Community::VoteAudit
			logger.debug "CHANGED VOTEAUDIT"
			voter = @vote_target.vote.voter
			@chained_target = voter if (!voter.nil? && (voter != current_user))
		end

		@auditable = @chained_target.auditable

		vote_type = "like"
		@vote_scope = nil
		@auditable.vote_by(:voter => @vote_target, :vote => vote_type, :vote_scope => @vote_scope) if @chained_target.class.name == "User" #@chained_target.is_a?(User)

		@users = User.all
	end
=end
	# POST '/vote/:otype(/:oid)(/:vtype)(/:vscope)'
	def vote
		#TODO: add the ability to lock voting by item, 
		# or globally turn off unvoting
		# or globally turn off unvoting after a certain time
		# or globally permit certain user roles to unvote
		@show_user_audit_scores = false
		
		@voting = Community::Voting.new(params:params,user:current_user,is_admin:is_admin?,logger:logger)
		
		@voting.log_vote!

		# impression = impressionist(@voting.vote_target, "Voting",{},{})
		#ViewLog.add(current_user, @voting.vote_target.otype_guessed, @voting.vote_target.id, DateTime.now, nil, params[:extra], impression.request_hash, logger) unless @voting.vote_target.nil?
		
		if is_admin? || @show_user_audit_scores
			@users = User.all.order("id").page(params[:page]).per(10)
		end

		respond_to do |format|
	        format.html {custom_redirect @voting.vote_target}
	        format.js {}
	        format.json do 
	        	render json: {success:true}
	        end
	    end
	end

	def json_request?
    	request.format.json?
  	end

  	private

  	def custom_redirect target
  		redirect_to target
  	end


end
end