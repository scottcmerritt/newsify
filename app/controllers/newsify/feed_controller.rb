module Newsify
	FeedLink = Struct.new(:title, :otype,:icon_css) do
	 #def status
	 #   "Role #{name}: #{active ? 'Active' : 'Disabled'}!"
	 # end
	end

	class FeedController < SourcesController

	    before_action :feed_types, only: [:report,:start,:scroll]

	  	def self.controller_path
	      "community/feed" # sets the path from app/views/... to something else
	    end

	   # an interface for scrolling past headlines, if skipped then flag as uninterested
	   # GET /start/scroll/feed
	   def scroll
	    @page_size = 100
	    load_start_feed

	    
	    @data.each {|source| source.google_classify!(entities:true) unless source.classified?} if params[:classify]


	    respond_to do |format|
	      format.js { render "start"}
	      format.html
	    end

	   end
	     
	    def debug
	      @otype = params[:otype]
	      @id = params[:id]
	      @object = Source.find(@id)
	    end

	   def report
	    object = Community::Preview.get(params[:otype],params[:oid])

	    impression = impressionist(object, "Feed start")
	    ViewLog.add(current_user, object.otype_guessed, object.id, DateTime.now, nil, params[:extra], impression.request_hash, logger) if defined?(ViewLog) && !object.nil?

	    @data = Source.limit(1)
	   end



	   # /recent/feed
	   def recent
	    @page_size = 25

	    load_start_feed

	    render json: {:data=>@data.as_json(:user=>current_user,:vote_scopes=>["interesting","quality","spam"])}
	   end

	   # "/recent/voted/feed/(:label)"
	   def recent_voted
	    ids = ActsAsVotable::Vote.where("voter_type = ? AND voter_id = ? AND votable_type = ? AND created_at > ? AND vote_flag = ?","User",current_user.id,"Source",7.days.ago, true).pluck(:votable_id)
	    render json: Source.where(id: ids)
	   end

	   # "/recent/ignored/feed/(:label)"
	   def recent_ignored
	    ids = ActsAsVotable::Vote.where("voter_type = ? AND voter_id = ? AND votable_type = ? AND created_at > ? AND vote_flag = ?","User",current_user.id,"Source",7.days.ago, false).pluck(:votable_id)
	    render json: Source.where(id:ids)
	   end

	   def start
	      @page_size = 2

	      load_start_feed

	   end

	  def mine
	    build_test_data if params[:build_test_data]
	    build_test_ratings if params[:build_test_ratings]

	    @otype = "feed"
	    
	    @js_url = "/feed.js"
	    setup_news_feed
	    #@sources = @sources.order("id DESC").page(params[:page])

	    respond_to do |format|
	      format.html {render "index"} #{ render "/sounds/browse"}
	      format.js { render "index.js" }
	      format.json {render :json => {describe:@labeled_data}} #@data}
	    end
	  end

	  def labeled
	    @otype = "feed"
	    
	    @js_url = "/feed/#{@label}.js"
	    setup_news_feed

	    render "index"
	  end

	private

	  def feed_types
	    links = ["unrated"] + Import.group(:keyword).pluck(:keyword)

	    @feed_types = []
	    @feed_types.push FeedLink.new("For me","unrated_by_me","star")
	    links.each do |link|
	      @feed_types.push FeedLink.new(link,link,"newspaper")
	    end
	  end

	   def build_test_data
	    org_id = 802

	    User.all.each do |user|
	      now = Date.today
	      date = (now - Random.rand(10))

	      source = Source.new(title: "Dated test article",org_id: org_id,createdby: user.id,created_at: date)
	      source.save
	    end
	  end

	  def build_test_ratings
	    vote_count = 0
	    sources = Source.order("id desc").limit(100) #.where(org_id: 802)
	    sources.each do |source|
	      User.where.not(id: [1,4,10,13]).each do |user|
	        vote_scope = "interesting"

	          vote_count+=1

	          if Random.rand(3) > 1
	            source.vote_by :voter => user, :vote => "like", :vote_scope => vote_scope
	          else
	            source.vote_by :voter => user, :vote => "down", :vote_scope => vote_scope
	          end

	      end

	    end

	    ActsAsVotable::Vote.order("created_at desc").limit(vote_count).each do |vote|
	      test_date = Random.rand(60*60*24).seconds.ago
	      vote.update_attribute(:created_at,test_date)
	      vote.voter.add_points(1, category: 'equity-eligible')
	    end
	  end

	  def get_some_sources days_ago: 2, page:1, page_size: 20, offset: 0, grouped: true
	  	@feed_type = "within #{days_ago} days"
	  	data = custom_unrated_by_me(:nojoin)
		.where("created_at > ?",days_ago.days.ago)
		if offset != 0
			data = data.offset(offset).limit(page_size)
		else
			data = data.page(page).per(page_size)
		end
		data = data.where(is_group: true) if grouped == true
		data = data.where(is_group: false) if grouped == false
		@feed_type+= " (not grouped)" if grouped.nil? || !grouped

		return data
	  end

	  def load_start_feed
	    
		@otype = params[:otype] || "source"
		@feed_type = @otype

		@page = params[:page]
		@offset = params[:offset] ? params[:offset].to_i : 0
		@append = params[:append].to_s == "true" ? true : false

		@days_ago = 2

		# TODO: exclude votes from current user, 
		# do mixture of 1) high interest items from friends and others and 2) un-reviewed headlines
		@data = get_some_sources days_ago: @days_ago, page: @page, page_size: @page_size, offset: @offset, grouped: true
		@data = get_some_sources days_ago: @days_ago, page: @page, page_size: @page_size, offset: @offset, grouped: nil if @data.total_count < 10

		if @data.total_count < 10
			@days_ago+=4
			@data = get_some_sources days_ago: @days_ago, page: @page, page_size: @page_size, offset: @offset, grouped: true
			@data = get_some_sources days_ago: @days_ago, page: @page, page_size: @page_size, offset: @offset, grouped: nil if @data.total_count < 10	     	
		end

       	if @data.total_count == 0
			@feed_type = "Interest predicted"
			@data = custom_unrated_by_me_guessed(current_user)
			.where("created_at > ?",@days_ago.days.ago)

	        if @offset != 0
	          	@data = @data.offset(@offset).limit(@page_size)
	        else
	          	@data = @data.page(@page).per(@page_size)
	        end

        	@data = @data.where(is_group: false)
       	end

	      if @data.total_count == 0
	        @feed_type = "Not grouped"
	        @data = custom_unrated_by_me(:nojoin).offset(@offset)
	        .where("created_at > ?",@days_ago.days.ago)
	        if @offset != 0
	          @data = @data.offset(@offset).limit(@page_size)
	        else
	          @data = @data.page(@page).per(@page_size)
	        end
	        @data = @data.where(is_group: false) #,group_id: nil)    
	      end

	      if false && @data.length == 0
	        @feed_type = "Unrated by me, others found it interesting"
	        @data = custom_unrated_by_me(:labeled,"interesting")
	        .where("created_at > ?",@days_ago.days.ago).offset(@offset)
	        .page(@page).per(@page_size)    
	      end    

	      if false && @data.length == 0
	         @data = unrated.offset(@offset) #_by_me
	        .order(created_at: :desc)
	        .page(@page).per(@page_size)
	      end



	  end

	end
end