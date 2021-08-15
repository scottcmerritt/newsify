module Newsify
	class OrgsController < ApplicationController

		before_action :load_entities, only: [:inline_change,:index,:show,:edit,:update,:join,:leave,:approve_member,:deny_member,:remove_user]
		before_action :load_pending_member, only: [:approve_member,:deny_member,:remove_user]
		before_action :load_groups, only: [:index,:networks]
		before_action :load_permissions, only: [:show,:join]

		def new
			@org = Community::Org.new
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


		def index
			Community::Org.all.each {|org| org.cache_content_scores!(min_votes:1) } if params[:build_cache]

			@page = params[:page] ? params[:page].to_i : 1
			@page = 1 if @page < 1

			@org_types = 
			{
				"news":
					{:name=>"News organizations",:field=>"is_news"},
				"companies":
					{name:"Companies",field:"is_company"},
				"non_profits":
					{name:"Non profits",field:"is_non_profit"},
				"blogs":
					{:name=>"Blogs",:field=>"is_blog"}
			}
			@org_type = params[:org_type].to_sym if params[:org_type]
			@org_type = @org_types.key?(@org_type) ? @org_types[@org_type][:field] : nil

			if params[:q]
				@query = params[:q]

				prepped = "%#{@query.downcase}%"
				@orgs = Community::Org.select("orgs.*")
				.where("lower(name) LIKE ?",prepped)
			end

			@orgs = @orgs.where("#{@org_type} = ?",true) unless @org_type.nil?

			@orgs = @orgs.page(params[:page])

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
		
		# POST '/remove/org_user/:id/:user_id'
		def remove_user
			@room = Room.find_by(id: params[:room_id]) if defined?(Room)

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
			@room = Room.find_by(id: params[:room_id]) if defined?(Room)

			@org.member_approve! @pending_member, current_user
			@org.reload

			check_org_room_participation
			broadcast_room_members unless @room.nil?

			locals = {:org=>@org,:room=>@room}
			#@org.broadcast_approval @pending_member
	     	notification = render_to_string(:partial=>"community/orgs/notice/added",:locals=>locals,:layout=>false)
	     	NotificationChannel.broadcast_to @pending_member, {:notification=>notification,:org_id=>@org.id} if defined?(NotificationChannel)
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
		


		protected

		def permitted_parameters
	    	params.require(:org).permit(:name,:is_group,:is_news,:is_company,:is_network,:is_seller,:approve_members,:icon_css)
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

		def check_org_room_participation
			if @room.nil? || !@room.room_orgs.where(org_id:@org.id).exists?
				@room = nil
			end
		end


	end
end