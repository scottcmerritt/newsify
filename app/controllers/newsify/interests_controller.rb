module Newsify
	class InterestsController < ApplicationController
		include Community::UserUtility

		before_action :load_entities
	    def interests_edit
	      @query = params[:q]
	      @items = Item.kinda_spelled_like @query
	      #@items = @labeled.page(params[:page]).per(10)

	    end

	    def interests
	    	@order = params[:order] == "desc" ? :desc : :asc

	      if params[:clean] && is_admin?
	        ItemInterest.all.each do |ii|
	          if Item.find_by(id:ii.item_id).nil?
	            ii.destroy
	          end
	        end
	      end
	      
	      if view_news_prefs?      
	        current_user.settings(:browsed).update!('interests' => "news") unless !current_user.respond_to?(:settings) || current_user.settings(:browsed).interests == "news"

	        @export_link = (@order == :desc) ? newsify.profile_interests_path(id:@user.id,format:"json") : newsify.profile_disinterests_path(id:@user.id,format:"json")
	        @bg_color = @order == :desc ? "green" : "red"
	        
	        @interests = ItemInterest.by_user @user, limit: 200, order: @order
	        if @interests.nil? || @interests.length == 0
	          ItemInterest.calc_interests! @user, remove: true
	          @interests = ItemInterest.by_user(@user, limit: 200, order: @order)

	        end

	        respond_to do |format|
	          format.html {render "interests"} #{ render "/sounds/browse"}
	          format.js { render "interests.js" }
	          format.json {send_data @interests.limit(1000).to_json(only: [:item_id,:name,:interests,:itype,:wiki_url]) }
	        end

	      else
	        redirect_to profile_path(id:params[:id])
	      end
	    end

	    private
	      def load_entities
		    @user = User.find_by(id: params[:id] ? params[:id] : current_user.id)
		  end



	end

end