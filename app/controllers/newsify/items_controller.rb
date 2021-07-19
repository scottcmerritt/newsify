module Newsify
	class ItemsController < ApplicationController
		require "custom_sort"

		include Newsify::NewsGeneral, Community::LabeledData #, RoomUtility
		before_action :get_links
		before_action :set_otype

		before_action :load_entities
		before_action :load_parents, only: [:new,:edit]

		def self.controller_path
    		"community/items" # change path from app/views/ideas to app/views/tasks
  		end

		def index
			do_test_add if params[:test_add]

			@no_join = params[:join] == true ? false : true
			@hide_recency = true

			@otype = "item"
			setup_label_sort #sets up sort_by, using default values if no label is set
			setup_time_decay
			@js_url = "/items.js"

			setup_labeled_data Item, "items", "Item"
			#add_friend_filter
			do_labeled_query

			respond_to do |format|
				format.html {render "index"} #{ render "/sounds/browse"}
				format.js { render "index.js" }
				format.json {render :json => {describe:@labeled_data}} #@data}
			end
		end

		# GET /types/items/:itype
		def itype
			@itypes = Item.select("itype").distinct.pluck(:itype)
		end

		def index
			do_test_add if params[:test_add]

			@no_join = params[:join] == true ? false : true
			@hide_recency = true

			@otype = "item"
			setup_label_sort #sets up sort_by, using default values if no label is set
			setup_time_decay
			@js_url = "/items.js"

			setup_labeled_data Item, "items", "Item"
			#add_friend_filter
			do_labeled_query

			respond_to do |format|
				format.html {render "index"} #{ render "/sounds/browse"}
				format.js { render "index.js" }
				format.json {render :json => {describe:@labeled_data}} #@data}
			end
		end

		def labeled
			@sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
			@sort_order = "DESC"

			@label = (@mod_labels+@labels).include?(params[:label]) ? params[:label] : nil

			@order_text = @sort_by[0]

			@order_text = "cached_weighted_#{@label}_average" unless @label.nil? #  "cached_weighted_score"

			@labeled = Item.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = items.id")
			.where("vote_caches.resource_type = ?","Item")
			.order("#{@order_text} #{@sort_order}").page(params[:page])

			render "index"
		end

	  def show

	    redirect_to @item.orgs[0] if params[:gogroup]
	    
	    impressionist(@item, "Show item",{})
	    #@item.add_google_category "/Computers & Electronics/Programming/Java (Programming Language)",0.55

	    @otype = "item"
	    setup_label_sort #sets up sort_by, using default values if no label is set
	    setup_time_decay
	    @js_url = "/items.js"

	    setup_labeled_data Item, "items", "Item"
	    #add_friend_filter

	    #@labeled = @labeled.where(itype: params[:itype]) if params[:itype]
	    @no_join = true
	    @labeled = @labeled.where(parent_id: @item.id)
	    @labeled = @labeled.where.not(itype:"CATEGORY") unless params[:itype]
	    add_order_by

	    @categories = Item.where(parent_id:@item.id,itype:"CATEGORY")

	  	preview_container = "#waveFormPreview"
	    @audio_obj = {:id=>'tests',:rowIndex=>'Bottom',:usePreview=>true,:container=>preview_container,:audioUrl=>'https://meritocracy-me.s3-us-west-1.amazonaws.com/sounds/1077c2cd-efeb-4555-b7f9-d66a3234de05/GreatDivide.mp3'}

	    entities_run = params[:entities] ? true : false
	    @classified = @item.google_classify! entities: entities_run, exclude_item_ids:[@item.id] if params[:classify]
	    #@init_page = :preview=>{:audio=>{:id=>'tests',:rowIndex=>'Bottom',:usePreview=>true,:container=>preview_container,:audioUrl=>'https://meritocracy-me.s3-us-west-1.amazonaws.com/sounds/1077c2cd-efeb-4555-b7f9-d66a3234de05/GreatDivide.mp3'}}}
	    
	    @connections = current_user.respond_to?(:friends) ? current_user.friends.where("friendships.friendable_type = ?", "User").where.not("friendships.friendable_id = ?",current_user.id) : nil



	    @interested = {
	      all:@item.favoritors_by_type('User').where.not("favorites.favoritor_id = ?",current_user.id),
	      connections:@item.favoritors_by_type('User').where("favorites.favoritor_id IN (?)",@connections.pluck(:friendable_id)) ,
	      nearby:[]
	    } if @item.respond_to?(:favoritors_by_type)

	  end


	  protected

		def do_labeled_query
			@labeled = @labeled.where.not(itype: ["SURGE_ITEM","SURGE_MENU"])

			if params[:q] && !params[:q].blank?
			  @query = params[:q]
			  @labeled = Item.respond_to?(:kinda_spelled_like) ? Item.kinda_spelled_like(@query) : Item.basic_search(@query) 
			  @labeled = @labeled.page(params[:page]).per(10)
			else
			  @labeled = @labeled.where(itype: params[:itype]) if params[:itype]

			#    @labeled = @labeled.where("parent_id is null OR parent_id = 1")
			  @labeled = @labeled.where(parent_id: params[:parent_id]) if params[:parent_id] #unless params[:parent_id].nil?
			  add_order_by #unless ActiveRecord::Base.connection.instance_values["config"][:adapter] == "sqlite3"
			end
		end

		def set_otype
			@otype = "items"
		end
	
		def load_parents
			@parents = Item.where(:itype=>"CATEGORY",:parent_id=>0).order("name ASC")
		end

		def load_entities
			@itypes = ["TOPIC","PERSON","SOUND","ARTICLE"]
			@item = Item.find_by(id: params[:id]) if params[:id]
		end


		def do_test_add
			if params[:test_add]
			  
			  test_itype = "OTHER"
			  #["1","2","3","4"]
			  30.times.each do |row|
			  	test_name = "test topic #{row}"

			    item = Item.where("LOWER(name) = ? AND itype = ?",test_name.downcase,test_itype).first
			    item = Item.create(name:test_name,itype:test_itype,wiki_url:nil) if item.nil?
			  end
			end 
		end

	end
end
