module Newsify
	class Feed
		attr_accessor :model, :user, :params, :data, :sort_by,:sort_order, :time_decay_text, :recent_relevance, :label, :labels, :labels_all
		def initialize model: Source, **options
			self.model = model
			self.params = options[:params]

			# for labeled/sorted data
			self.sort_by = options[:sort_by]
			self.label = options[:label]
			
			self.set_default_labels! unless options[:defaults] == false
			self.labels_all = options[:labels_all] if options[:labels_all]



			# loads data into self.data IF calling METHOD requests it
			self.load! if options[:load]

			self.user = options[:user]
		end

		def set_default_labels!
			self.labels_all = (Community::Voting.votescopes_main + Community::Voting.votescopes_moderation)
		end

		def table_name
			self.model.table_name
		end

		def target_type
			self.model.to_s
		end

		def page
			self.params[:page]
		end

		# their saved sources (aka favorites)
		def saved_data user
			user.favorited_by_type(self.target_type).page(self.page)
		end

		def load!
			tn = self.table_name

			tn_single = tn.singularize

			join_topics = (tn_single + "_topics").to_sym

			if self.params[:oid]
				@labeled = self.model.select("#{tn}.*").joins(join_topics)
				@labeled = @labeled.where(join_topics => {item_id: self.params[:oid]})
			elsif self.params[:author_id]
				@labeled = self.model.select("#{tn}.*").joins("LEFT JOIN source_authors ON source_authors.source_id=sources.id")
				@labeled = @labeled.where("source_authors.author_id = ?",self.params[:author_id])
			elsif self.params[:import_id]
				@labeled = self.model.select("#{tn}.*").joins("LEFT JOIN import_sources ON sources.id = import_sources.source_id")
				.where("import_id = ?",self.params[:import_id])
			else
				@labeled = self.model.select("#{tn}.*")
			end
	
			@labeled = @labeled.where(org_id:self.params[:org_id]) if self.params[:org_id]

			@labeled = @labeled.order("#{tn}.created_at DESC")
			@labeled = @labeled.page(self.page).per(20)
			self.data = @labeled
		end

		def filter!
			self.setup_label_sort
			self.setup_time_decay

			self.setup_labeled_data
			self.add_order_by

			return self.recent_relevance, self.label, self.sort_order

		end

		#TODO: pull from class variables
		def setup_labeled_data #model = Newsify::Source, table_name="sources", resource_type = "Newsify::Source"
	      
	      if self.time_decay_text.nil? #@lambda_val.nil?
	        self.data = self.model.select("#{self.table_name}.*") #,1 as time_decay, #{@order_text} as net_score")
	      else
	        #@order_text = @time_decay_text+"*#{@order_text}"
	        self.data = self.model.select("#{self.table_name}.*") #  ,#{@time_decay_text} as time_decay, #{@order_text} as net_score")
	      end
=begin
      unless @no_join
        @labeled = @labeled.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = #{table_name}.id")
        .where("vote_caches.resource_type = ?",resource_type)
      end
=end

	    end



		 # sets @time_decay_text, @recent_relevance and updates current_user.settings(:filter)[:recency]=> @recent_relevance
	    def setup_time_decay
	    	#require 'custom_sort' # phasing out
	    	require 'sortify'
	       # recency = 0 = High, Med, Low, None

	       if self.params[:recency]
	          self.recent_relevance = self.params[:recency].to_i
	          self.settings(:filters).update!('recency' => self.recent_relevance) if !self.user.nil? && self.user.respond_to?(:settings)
	        else
	          self.recent_relevance = !self.user.nil? && self.user.respond_to?(:settings) ? self.user.settings(:filters).recency : 0
	        end
	#      @recent_relevance = params[:recency] ? params[:recency].to_i :  2 

	      self.time_decay_text = Sortify::SortFields.time_decay_adjusted(self.model.table_name,self.recent_relevance)
	    end

	   	def setup_label_sort
	      self.label = !self.labels_all.nil? && self.labels_all.include?(self.params[:label]) ? self.params[:label] : nil
	      #@sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
	      self.sort_order = "DESC"
	            
	      #@order_text = @no_join ? "id" : @sort_by[0]
	      #@order_text = "(cached_weighted_#{@label}_average * cached_weighted_#{@label}_total)" unless @label.nil? #  "cached_weighted_score"
	    	return self.label, self.sort_order
	    end

	    def add_order_by order_text = nil
	#      @labeled = @labeled.order("#{order_text.nil? ? @order_text : order_text} #{@sort_order}")
	      query_name = @no_join ? "nojoin" : (self.label == "blended" ? "blended" : "labeled")

	      #@labeled = ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3" ? @labeled : @labeled.sortify(query_name,label: @label.nil? ? nil : Arel.sql(@label),recency_key: @recent_relevance,sort_order: @sort_order.nil? ? nil : Arel.sql(@sort_order))
	      self.data = self.data.sortify(query_name,label: self.label.nil? ? nil : Arel.sql(self.label),recency_key: self.recent_relevance,sort_order: self.sort_order.nil? ? nil : Arel.sql(self.sort_order))
	      
	      #if ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3"
	      #	sqlite_order_by
	      #else
		    #  @labeled = @labeled.sortify(query_name,label: @label,recency_key: @recent_relevance,sort_order: @sort_order)
		    #end
	      self.data = self.data.page(self.page)
	    end


	end
end