class OrgsController < ApplicationController
#	include RoomUtility

	

	#not implemented yet
	APPROVAL_TYPES = {0=>"standard",1=>"any member",2=>"two members",3=>"three members",4=>"four members",5=>"majority vote"}

	before_action :load_entities, only: [:inline_change,:index,:show,:edit,:update,:join,:leave,:approve_member,:deny_member,:remove_user]
	before_action :load_pending_member, only: [:approve_member,:deny_member,:remove_user]
	before_action :load_groups, only: [:index,:networks]
	before_action :load_permissions, only: [:show,:join]

	include Newsify::NewsGeneral

	#def self.controller_path
    #  "news/orgs" # change path from app/views/orgs to app/views/news/orgs
  	#end

  	# inline editor for changing the name quickly
  	def inline_change
  		@output = {:status=>"OK"}

  		if is_admin? || @org.can_edit?(current_user)
  			@org.name = params[:value]
  			@org.save
  		else
  			@output = {:status=>"ERROR"}
  			@output = {status: 'error', msg: 'No permissions!'}
  		end
  		@output = @output.merge({:oid=>@org.id,:title=>@org.name})

		respond_to do |format|
        	#logger.debug "FORMAT: #{format.inspect}"
        	#format.html { render '/music/inline_status',:layout => false }
        	format.json { render :json => @output }
    	end
  	end

	def index
		redirect_to newsify.orgs_path if newsify
		@page = params[:page] ? params[:page].to_i : 1
		@page = 1 if @page < 1

		# User.page(3).without_count
		# then use <%= link_to_prev_page @users, 'Previous Page' %> and <%= link_to_next_page @users, 'Next Page' %>
		Community::Org.all.each {|org| org.cache_content_scores! } if params[:build_cache]
		
			
		if params[:q]
			@query = params[:q]

			prepped = "%#{@query.downcase}%"
			@orgs = Community::Org.select("orgs.*")
			.where("lower(name) LIKE ?",prepped)

		else
			if defined?(VoteCache)
				@orgs = Community::Org.select("orgs.*")
				.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = orgs.id")
				.order("cached_content_score DESC")
				.where("vote_caches.resource_type = ?","Community::Org")
			else
				@orgs = Community::Org.all
			end
			@org_type = "is_news" #@org_types.key?(params[:org_type]) ? @org_types[params[:org_type][:field]] : nil
			@orgs = @orgs.where("#{@org_type} = ?",true) unless @org_type.nil?

		end
		@orgs = @orgs.page(params[:page]).per(20)


	  @top_voted = OrgCustom.top_orgs if defined?(VoteCache) #OrgCustom.top_voted(10)
  	 
	end

	def networks
		@orgs = Community::Org.where(is_network: true).page(params[:page]).per(20)
		render "index"
	end
	

	def show
		
		
		
		#@org.clear_users!
	end

	def new
		@org = Community::Org.new
	end

	# POST '/remove/org_user/:id/:user_id'
	def remove_user
		@room = Room.find_by(id: params[:room_id])
		@org.member_deny! @pending_member, current_user
		@org.reload

		check_org_room_participation
		broadcast_room_members unless @room.nil?

		unless @room.nil?
			redirect_to controller:"rooms",action:"roles",id:@room.id
		else
			render "remove_user", :content_type => 'text/javascript'
		end
	end


	def approve_member
		#TODO: check to make sure they are in the room
		@room = Room.find_by(id: params[:room_id])

		@org.member_approve! @pending_member, current_user
		@org.reload

		check_org_room_participation
		broadcast_room_members unless @room.nil?

		locals = {:org=>@org,:room=>@room}
		#@org.broadcast_approval @pending_member
     	notification = render_to_string(:partial=>"community/orgs/notice/added",:locals=>locals,:layout=>false)
     	NotificationChannel.broadcast_to @pending_member, {:notification=>notification,:org_id=>@org.id}
		unless @room.nil?
			redirect_to controller:"rooms",action:"roles",id:@room.id
		else
			render "community/orgs/update_join_status", :content_type => 'text/javascript'
		end
	end

	def deny_member
		@room = Room.find_by(id:params[:room_id])

		@org.member_deny! @pending_member, current_user
		@org.reload

		check_org_room_participation

		locals = {:org=>@org,:room=>@room}
     	notification = render_to_string(:partial=>"community/orgs/notice/removed",:locals=>locals,:layout=>false)
     	NotificationChannel.broadcast_to @pending_member, {:notification=>notification,:org_id=>@org.id}
		unless @room.nil?
			redirect_to controller:"rooms",action:"roles",id:@room.id
		else
			render "community/orgs/update_join_status", :content_type => 'text/javascript'
		end
	end
	def join
		@org.join! current_user
		@pending_member = current_user

		#@org = Org.find(params[:id]) if params[:id]
		@org.reload
		render "community/orgs/update_join_status"
	end

	def leave
		@org.leave! current_user
		@pending_member = current_user
		@org.reload
		render "community/orgs/update_join_status"
	end  

	#org_articles
	# POST '/orgs/articles(/:id)'
	def articles
		#@org = Org.find_by(id: params[:id])
	  	@sources = Source.select("sources.id as source_id, *").with_orgs.byOrg(@org_id).by_published_date(true)
	end


	# GET /orgs/info
	def info

	  	@with_hashkey_count = Source.where("NOT hashkey is NULL").count
	  	if params[:clear]
	  		#Org.all.delete_all
	  		#Author.all.delete_all
	  		#AuthorOrg.all.delete_all
	  		#Source.all.delete_all
	  		#SourceAuthor.all.delete_all

	  	end
	  	#@orgs = Org.select("*").order("name")
	  	@orgs = Community::Org.select("orgs.id,orgs.name,orgs.newsapi_key,COUNT(sources.id) as article_count")
	  	.joins("LEFT JOIN sources ON sources.org_id = orgs.id")
	  	.group("orgs.id,orgs.name,orgs.newsapi_key")
	  	.where("is_duplicate = ?",false)
	  	.order("article_count DESC")

	  	@authors = Author.count #Author.select("*").order("name")
	  	@sources = Source.count #Source.all
	  	@sources_duplicates = Source.where("is_duplicate = ?",true)
	  	#TODO: fix this, it's not working
	  	if @sources_duplicates.length == 0
	  		@sources_duplicates = Source.joins("LEFT JOIN sources as s2 ON s2.hashkey = sources.hashkey")
	  		.where("NOT sources.id = s2.id").count
	  	end
  	#news_item = @sources[0]

=begin
  	require 'digest'
  	@sources.each do |source|
  		if source.hashkey.nil?
	  		source.title = source.title.strip unless source.title.nil?
	  		source.description = source.description.strip unless source.description.nil?
	  		source_hash_string = ((source.title.nil?) ? "" : source.title) + ((source.description.nil?) ? "" : source.description)
	  		source.hashkey = Digest::SHA256.hexdigest(source_hash_string)

	  		source.is_duplicate = Source.exists?(:hashkey=>source.hashkey)
	  		source.save
	  	end
  	end
=end


		@orgs_multiple_authors = Community::Org.select("orgs.id,orgs.name,orgs.newsapi_key,COUNT(authors.id) as author_count")
		.joins("LEFT JOIN author_orgs ON author_orgs.org_id = orgs.id")
		.joins("LEFT JOIN authors ON authors.id = author_orgs.author_id")
		.group("orgs.id,orgs.name,orgs.newsapi_key")
		.order("author_count DESC")
		.limit(10000)

		@author_counts = {}
		@orgs_multiple_authors.each do |oma|
			@author_counts[oma.id] = oma.author_count
		end

  	#.limit(20)

	  	if false
		  	keyword = "bitcoin"
		  	item_id = Item.lookup_or_create(keyword, nil,"concept",false,true,true)

		  	@sources.each do |source|
		  		if source.title.downcase.include?(keyword)
		  			st = SourceTopic.new(:source_id=>source.id,:item_id=>item_id,:createdby=>current_user.id)
		  			st.save
		  		end
		  	end
		end

		#render "news/orgs/info"
	end


	

	def edit



	end

	def update
		if @org.update(permitted_parameters)
	      flash[:success] = "Org #{@org.name} was updated successfully"
	      redirect_to @org
	    else
	      render :new
	    end
	end



	def create
		@org = Community::Org.new permitted_parameters

		@org.createdby = current_user.id

		if @org.save

			 flash[:success] = "Org #{@org.name} was created successfully"
      
		      #@user = User.find(1)
		      #RoomChannel.broadcast_to @user, @user

		      if permitted_parameters[:is_seller] == "1"
		      	redirect_to controller:"surge_org",action:"seller_setup",org_id:@org.id, welcome:true
		      else
		      	redirect_to @org
		      end
		else
			render :new
		end
	end

	protected

	def permitted_parameters
    	params.require(:org).permit(:name,:is_group,:is_news,:is_blog,:is_company,:is_non_profit,:is_network,:is_seller,:approve_members,:icon_css)
  	end

  	def load_permissions
		@show_member_status = (is_admin? || is_moderator?)
	end

  	def load_entities
	    @orgs = Community::Org.limit(100)
	    @org = Community::Org.find(params[:id]) if params[:id]
	    @user = current_user
  	end

  	def load_groups
  		 @groups = Community::Org.where("is_news = ?",false)
  		 .page(params[:org_page]).per(20)
  	end

  	def load_pending_member
		@pending_member = User.find_by(id: params[:user_id])
	end
	def broadcast_room_members
		custom = {:people=>load_room_people}
     	RoomChannel.broadcast_to @room, custom
    end
	def check_org_room_participation
		if @room.nil? || !@room.room_orgs.where(org_id:@org.id).exists?
			@room = nil
		end
	end
end