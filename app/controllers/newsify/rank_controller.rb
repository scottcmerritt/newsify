module Newsify
class RankController < ApplicationController
	before_action :custom_authenticate_user!
	before_action :set_user, only: [:choose,:interested]
	before_action :load_choices, only: [:choose]
	before_action :load_matches, only: [:interested] if respond_to?(:matchify)
	
	include Community::UserUtility # needs user loaded
	def self.controller_path
		"community/rank" # sets the path from app/views/... to something else
	end

	
	def interested
		@page_size = 10
		@page = params[:page]

		@data_view = params[:view].to_sym if params[:view] && [:mutual,:mine,:me].include?(params[:view].to_sym)

		redirect_to(controller: "rank", action: "interested", id: nil,otype: params[:otype]) if current_user.id == params[:user_id].to_i
	end


	# swipe/:otype
	def swipe

		@items = User.limit(100).sample(1)

		if request.post?
			@output = []
			@choices = params[:choices] #choose_params
			@choices.each do |k,v|
				@output = "#{k} : #{v["oid"]}, #{v["score"]}"
			end
			#@choices = JSON.parse(@choices)
		end

		respond_to do |format|
        	format.html {} #{ render "/sounds/browse"}
        	format.js { render "choose.js"}
        	#format.json {render :json => "no data"} #@data}
    	end
	end

	# GET/POST /choose/:otype
	def choose
		#@items = User.limit(100).sample(4)
		
		@items = @items.sample(4)
		@items_past = []

		#@items = User.limit(100).sample(1)

		@message = nil
		@log = []
		@errors = []


		# NOTE: an impression is logged ONCE, only on load: 
		# I commented out the other time it was logged

		if request.post?
			@output = []
			@choices = params[:choices] #choose_params
			@choices.each do |k,v|
				begin
					#voting = Community::Voting.new(params:v,user:current_user,is_admin:is_admin?,logger:logger)
					#impressionist(voting.vote_target)
					@items_past.push log_choice!(choice: v, key: k)
				rescue Exception => e
					@errors.push e
				end
			end

			@status = @errors.length == 0
			@message = @errors.length == 0 ? "Choices saved" : "Errors saving: #{@errors.join(", ")}"
		else
			load_stats


			@items.each {|item| impressionist(item)}
		end

		respond_to do |format|
        	format.html {} #{ render "/sounds/browse"}
        	format.js { render "choose.js"}
        	format.json {render :json => build_choice_json(status: @status, message: @message) }
    	end

	end

	def info

		@status = true
		@message = "Loading info"

		respond_to do |format|
        	format.html {} #{ render "/sounds/browse"}
        	format.js { render "choose.js"}
        	format.json {render :json => build_info_json(status: @status, message: @message) }
    	end
	end

	def details
		# TODO: it defaults to PHOTOS, but add various detail TYPES

		@status = true
		@message = "Loading details"

		respond_to do |format|
        	format.html {} #{ render "/sounds/browse"}
        	format.js { render "choose.js"}
        	format.json {render :json => build_details_json(status: @status, message: @message) }
    	end
	end

	private

	def set_user
		if params[:action] == "choose"
			@user = current_user
		else
			@user = User.find_by(id:params[:user_id]) 
			@user = current_user if @user.nil?
		end
	end

	

	def load_stats
		#@stats = {likes:current_user.votes(vote_scope:vote_scope).up.count,dislikes:current_user.votes(vote_scope:vote_scope).down.count}
		vote_p = {vote_scope: get_vote_scope, vote_flag: true} #votable_id: votable.id, votable_type: votable.class.base_class.name,
		
		@stats = {likes:current_user.find_votes(vote_p).count,dislikes:current_user.find_votes(vote_p.merge({vote_flag:false})).count}
	end

	def build_choice_json status:nil, message:nil

		locals = {:items=> @items, :items_past=> @items_past}
		html = render_to_string(:partial=>"community/rank/parts/choose",:locals=>locals,:layout=>false,:formats => [:html])
		load_stats
		html_stats = render_to_string(:partial=>"community/rank/parts/stats",:locals=>{user:current_user,stats:@stats},:layout=>false,:formats => [:html])

		return {:status=>status,:message=>message,:html=>html, :html_stats=>html_stats}
	end

	def build_info_json status:nil, message:nil

		#locals = {:items=> @items, :items_past=> @items_past}
		@target = User.find_by(id:params[:oid])
		impressionist @target
		locals = {user: @target,media_viewer:true,show_edit:false,show_engage:false,show_history:false,show_prefs:true,wrap_css:"px-2 pt-1 mt-0 bg-light border rounded-top"}
		html = render_to_string(:partial=>"users/parts/show",:locals=>locals,:layout=>false,:formats => [:html])
		#load_stats
		#html_stats = render_to_string(:partial=>"community/rank/parts/stats",:locals=>{user:current_user,stats:@stats},:layout=>false,:formats => [:html])

		return {:status=>status,:message=>message,:html=>html}
	end

	def build_details_json status:nil, message:nil

		#locals = {:items=> @items, :items_past=> @items_past}
		@target = User.find_by(id:params[:oid])
		impressionist @target
		locals = {user: @target,photos: @target.dating_photos,show_edit:false,show_engage:false,show_history:false,show_prefs:true,wrap_css:"px-2 pt-1 mt-0 bg-light border rounded-top"}
		html = render_to_string(:partial=>"media/photos/overlay",:locals=>locals,:layout=>false,:formats => [:html])
		#load_stats
		#html_stats = render_to_string(:partial=>"community/rank/parts/stats",:locals=>{user:current_user,stats:@stats},:layout=>false,:formats => [:html])

		return {:status=>status,:message=>message,:html=>html}
	end
	


	def log_choice! choice:, key:
		# get object, apply weighting to :vote_weight=>10, 5, 1, dislike the last one
		@log.push("#{key} : #{choice["oid"]}, #{choice["otype"]}, #{choice["score"]} ")
		logger.debug "inside choices"
		logger.debug choice

		obj = Community::Preview.get(choice["otype"],choice["oid"])
		case choice["score"].to_i
		when 0
			current_user.likes(obj,vote_scope:get_vote_scope,vote_weight: 4)
		when 1
			current_user.likes(obj,vote_scope:get_vote_scope,vote_weight: 1)
		when 2
			current_user.dislikes(obj,vote_scope:get_vote_scope,:vote_weight => 1)
		when 3
			current_user.dislikes(obj,vote_scope:get_vote_scope,vote_weight: 4)
		end
		return obj
	end

	def load_choices

		@location = params[:loc]
		geocoded = Community::UserProfile.geocode! @location, refresh: (params[:refresh] && is_admin?) unless @location.blank?

		my_picks = ActsAsVotable::Vote.where(voter_id:current_user.id,voter_type:get_voter_type,votable_type:get_votable_type,vote_scope:get_vote_scope) # ,vote_flag:true
		#.where.not(votable_id:current_user.id)


		@location_coords = geocoded ? [geocoded.lat,geocoded.lng] : current_user.coords
		search_p = params[:all] ? {} : current_user.seeking_prefs(basic_params.to_h)
		@users =  Community::UserSearch.search search_p, current_user, coords: @location_coords
		@users = @users.where.not(id:my_picks.pluck(:votable_id))
		#@matches = @users
		@items = @users.per(200)

		# NOTE: if we want to show distances from requested area, use @@location_coords
		@from_coords = @user.coords


	end

end
end