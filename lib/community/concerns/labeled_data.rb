module Community
	module LabeledData
	  extend ActiveSupport::Concern

	  included do
	    #before_action :method_here
	      before_action :load_labels, only: [:index,:labeled,:mine,:show]
	      
	  end
	  private
		  def setup_news_feed
	  		  setup_label_sort #sets up sort_by, using default values if no label is set
			    setup_time_decay
			    setup_labeled_data
			    add_friend_filter if current_user.respond_to?(:friends)
			    add_order_by
			end

	    def load_labels
	      @labels = Community::Voting.votescopes_main
	      @mod_labels = Community::Voting.votescopes_moderation
	    end

	    def setup_labeled_data model = Newsify::Source, table_name="sources", resource_type = "Newsify::Source"
	      if @time_decay_text.nil? #@lambda_val.nil?
	        @labeled = model.select("#{table_name}.*") #,1 as time_decay, #{@order_text} as net_score")
	      else
	        #@order_text = @time_decay_text+"*#{@order_text}"
	        @labeled = model.select("#{table_name}.*") #  ,#{@time_decay_text} as time_decay, #{@order_text} as net_score")
	      end
=begin
      unless @no_join
        @labeled = @labeled.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = #{table_name}.id")
        .where("vote_caches.resource_type = ?",resource_type)
      end
=end

	    end

	    def add_friend_filter
	      user_ids = current_user.friends.pluck(:id) + [current_user.id]
	      @labeled = @labeled.where("createdby IN (?)", user_ids) unless params[:all]
	    end

	    def add_order_by order_text = nil
	#      @labeled = @labeled.order("#{order_text.nil? ? @order_text : order_text} #{@sort_order}")
	      query_name = @no_join ? "nojoin" : (@label == "blended" ? "blended" : "labeled")

	      @labeled = ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3" ? @labeled : @labeled.sortify(query_name,label: @label.nil? ? nil : Arel.sql(@label),recency_key: @recent_relevance,sort_order: @sort_order.nil? ? nil : Arel.sql(@sort_order))
	      
	      #if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3"
	      #	sqlite_order_by
	      #else
		    #  @labeled = @labeled.sortify(query_name,label: @label,recency_key: @recent_relevance,sort_order: @sort_order)
		    #end
	      @labeled = @labeled.page(params[:page])
	    end

	    def sqlite_order_by
	    	@sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
				@sort_order = "DESC"

				@label = (@mod_labels+@labels).include?(params[:label]) ? params[:label] : nil

				@order_text = @sort_by[0]

				@order_text = "cached_weighted_#{@label}_average" unless @label.nil? #  "cached_weighted_score"


	    end

	    def setup_label_sort
	      @label = (@mod_labels+@labels).include?(params[:label]) ? params[:label] : nil
	      #@sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
	      @sort_order = "DESC"
	            
	      #@order_text = @no_join ? "id" : @sort_by[0]
	      #@order_text = "(cached_weighted_#{@label}_average * cached_weighted_#{@label}_total)" unless @label.nil? #  "cached_weighted_score"
	    end

	    def setup_time_decay
	    	require 'custom_sort' # phasing out
	    	require 'sortify'
	       # recency = 0 = High, Med, Low, None

	       if params[:recency]
	          @recent_relevance = params[:recency].to_i
	          current_user.settings(:filters).update!('recency' => @recent_relevance) if current_user.respond_to?(:settings)
	        else
	          @recent_relevance = current_user.respond_to?(:settings) ? current_user.settings(:filters).recency : 0
	        end
	#      @recent_relevance = params[:recency] ? params[:recency].to_i :  2 

	      @time_decay_text = Sortify::SortFields.time_decay_adjusted("sources",@recent_relevance)

	    end

	end


end