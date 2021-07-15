module Newsify
	class OrgsController < ApplicationController

		before_action :load_entities, only: [:inline_change,:index,:show,:edit,:update,:join,:leave,:approve_member,:deny_member,:remove_user]
		before_action :load_pending_member, only: [:approve_member,:deny_member,:remove_user]
		before_action :load_groups, only: [:index,:networks]
		before_action :load_permissions, only: [:show,:join]

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


	end
end