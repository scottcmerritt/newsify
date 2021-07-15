class OldSourcesController < ApplicationController
	include Newsify::NewsGeneral, LabeledData, ClassifyNews, FlagNews
  before_action :load_entities, only: [:show,:edit,:update]
  before_action :load_feed_report, only: [:info,:index,:mine,:start,:scroll,:report,:labeled,:my_interests]

  before_action :get_links
  before_action :set_otype

  skip_before_action :verify_authenticity_token, only: [:index,:labeled]

	def self.controller_path
      "news/sources" # change path from app/views/ideas to app/views/tasks
  end


  #GET /guesses/sources
  def guesses

    @target_ids = GuessScope.where(user_id:current_user.id,target_type:"Source").order("score DESC").pluck(:target_id)
    @data = recent_guesses @target_ids, :nojoin, nil, 3
    render json: @data
  end
  # GET /info/sources
  def info
    @info = {:rated=>current_user.rated(Source),:ratings=>current_user.ratings(Source),
            :unrated=>@unrated.count,:unrated_by_me=>@unrated_by_me.count}
    @info[:sources] = Source.count
    @info[:sources_recent] = Source.where("created_at > ?",2.days.ago).count

    @info[:sources_grouped] = Source.where("NOT group_id is null").count
    @info[:sources_recent_grouped] = Source.where("created_at > ? AND NOT group_id is null",2.days.ago).count


    render json: @info
  end

  def analyze
  #  s3 = Aws::S3::Client.new(
  #  access_key_id: 'your_access_key_id',
  #  secret_access_key: 'your_secret_access_key'
  #)

# Rails.application.credentials.aws[:access_key_id]
  @input = 'Victoria reports 41 new coronavirus cases, the state\'s lowest single-day increase in cases since June. It comes after the State Government unveiled its "roadmap to recovery" outlining four phases Victoria will progress through as restrictions are lifted.'
  
  @source = Source.find_by(id: params[:source_id])
  @input = @source.to_classify unless @source.nil?

  if params[:aws]
    client = Aws::Comprehend::Client.new(
  region: "us-west-2",
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  # ...
  )
    
    @response = client.detect_entities({
  text: @input, # required
  language_code: "en" #,#, # accepts en, es, fr, de, it, pt, ar, hi, ja, ko, zh, zh-TW
  #endpoint_arn: "arn:aws:iam::176424936852:group/chat-app"
  #endpoint_arn: "EntityRecognizerEndpointArn",
})
  end

  # classification is not very good for source headlines
  if params[:aylient]
    aylien = Summarize.new
    @classify = aylien.classify! @input

  end

  ga = GoogleAnalyze.new
  #@sentiment = ga.sentiment_from_text text_content: "I just ate a delicious meal at a restaurant"
  @classified = ga.classify_from_text text_content: @input

  @entities = ga.entities_from_text text_content: @input

  end

  # '/imported/sources/:import_id'
  def imported
    
    @labeled = Source.joins("LEFT JOIN import_sources ON sources.id = import_sources.source_id")
    .where("import_id = ?",params[:import_id]).page(params[:page])
    render "index"
  end



	def index
	   # TO UPDATE THE CACHED COUNTS
     #  Source.find_each(&:update_cached_votes)

     if params[:clean]
      clean_page = params[:clean_page]  ? params[:clean_page].to_i :  1
      clean_limit = params[:clean_limit] ? params[:clean_limit].to_i : 100
      clean_offset = (clean_page-1) * clean_limit

      Source.limit(clean_limit).offset(clean_offset).order("created_at DESC").each do |source|
        source.purge_duplicate_topics
      end

     end

		if params[:auto_ui]
			@auto_ui = true
		end

    @no_join = true
    @hide_recency = true

    @otype = "source"
    setup_label_sort #sets up sort_by, using default values if no label is set
    setup_time_decay
    @js_url = "/sources.js"

    setup_labeled_data
    #add_friend_filter

    extra_conditions = params[:org_id].nil? ? {} : {org_id: params[:org_id]}
    extra_conditions[:is_group] = true

    @labeled = @labeled.where(extra_conditions)

    add_order_by "id"
    

    #.order("id DESC").page(params[:page])

  
     respond_to do |format|
        format.html {render "index"} #{ render "/sounds/browse"}
        format.js { render "index.js" }
        format.json {render :json => {data: @labeled.as_json({:only=>[:id,:title],:user=>current_user,:vote_scopes=>["interesting","quality","spam"]})  }}
    end

	end

  def caches
    @caches = VoteCache.all
  end

   def labeled
      @otype = "source"
      setup_label_sort
      setup_time_decay
      @js_url = "/labeled/sources/#{@label}.js"

      #Source.where("title = ?","Dated test article").destroy_all

      setup_labeled_data
      #add_friend_filter
      add_order_by

      classify_sources @labeled if params[:classify]

      render "index"
  end

  def my_interests
    @export_link = sources_my_interests_path(format:"json")
     @hide_recency = true
    #@hide_news_menu = true
    @ids = []
    current_user.find_up_votes_for_class(Source, vote_scope: "interesting").each do |row|
      @ids.push row.votable.id

    end
    @labeled = Source.where(id: @ids).page(params[:page])
    respond_to do |format|
        format.html {render "index"} #{ render "/sounds/browse"}
        format.js { render "index.js" }
        format.json {send_data @labeled.page(1).per(1000).to_json(only: [:id,:title,:description,:url,:published_at,:hashkey]) }
    end
    
  end

  

  def classify

    @source = Source.find(params[:id])
    @word_count = @source.to_classify.scan(/\w+/).size
    
    @input = @source.to_classify #title + " " + @source.description
    #@input = 'Victoria reports 41 new coronavirus cases, the state\'s lowest single-day increase in cases since June. It comes after the State Government unveiled its "roadmap to recovery" outlining four phases Victoria will progress through as restrictions are lifted.'
    
    @classified = @source.google_classify! min_salience: 0.0 if params[:run]
    

    
    if params[:entities]
      @rows = @source.google_get_entities! min_salience: 0.0
    end


=begin
    aylien = Summarize.new
    @classify = aylien.classify! @input
    @classify[:categories].each do |row|
        item = Item.find_by(iptc_subject_code:row[:code].to_i)
        SourceTopic.create(source_id:@source.id,item_id:item.id,score:row[:confidence]) unless SourceTopic.where(source_id:@source.id,item_id:item.id).exists?
        
        #TODO: add entities from aws Comprehend

    end
=end
  end
  

	def new
		@source = Source.new
	end

	def edit

	end

	def update
		if @source.update_attributes(permitted_parameters)
	      flash[:success] = "Source #{@source.title} was updated successfully"
	      redirect_to @source
	    else
	      render :new
	    end
	  end



	def create
		@source = Source.new permitted_parameters

		@source.createdby = current_user.id

		if @source.save
			 flash[:success] = "Source #{@source.title} was created successfully"
		      #@user = User.find(1)
		      #RoomChannel.broadcast_to @user, @user
		      redirect_to @source #source_path @source
		else
			render :new
		end
	end


	
  # /article/:id
  def show

    @source = Source.find_by(id: params[:id].to_i)
    

    impression = impressionist(@source, "",{},{})
    @testing = 123
    if params[:clean]
      @purging = @source.purge_duplicate_topics
    end

    if params[:summarize] 
      summary_count = @source.summary_count
      if summary_count == 0
        @summarize_result = Summarize.from_sources @source
      end
    end

    source_hash_string = {:site=>"localhost",:table=>"sources",:id=>params[:id].to_i,:user_id=>0}.to_json.to_s
    @hashkey = Digest::SHA256.hexdigest(source_hash_string)

    if @source.first_content.nil?
      if params[:get_url]
        url = @source.url
        preview = @source.description
        n = 4
        preview = preview.split[0...n].join(' ')
        @output = Content.from_web(url,preview,logger)
        Content.save_content(@source,@output)
      end
    else
      @output = @source.first_content.misc #.nil? ? nil : JSON.parse(@content.misc)
    end
  end

  def opinions
    @source = Source.find_by(id: params[:id].to_i)


  end

  # /article/save/:id
  def save_article
    source_id = params[:id]
    article = params[:article]

    content = Content.select("id,article").where("source_id = ?",source_id).first
    content.article = article
    content.edited = true
    content.edited_on = DateTime.now
    status = false
    if content.save
      status = true
    end

    render :text => status
  end



  # /sources/photos
  def photos
    use_words = true
    search_always = true
    ignore_tags = true
    ignore_synonyms = true
    @search_term = nil

    @search_term = params[:s]

    tag_params
    @limit = params[:limit] ? params[:limit].to_i : 100
    @offset = params[:offset] ? params[:offset].to_i : 0

    @source_item = Item.find_by(id: @item_id)
    sel_sql = "DISTINCT(sources.id),sources.*,urlToImage as image_url"


    @images = []
#    images = Source.select("sources.id,urlToImage as image_url")
#    .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id")
#    .where("source_topics.item_id = ?",@item_id)
#    .limit(@limit)
#    .offset(@offset)
    if !(@source_item.nil? && @search_term.nil?)
      @search_term = @source_item.name if @search_term.nil?
      if ignore_tags
        @images = Source.select(sel_sql).where("id=?",0)
      else
        @images = Source.select(sel_sql)
        .with_topics
        .where("source_topics.item_id = ?",@source_item.id)
      end
      
      if @images.length < @limit || search_always
        @query_names = [@search_term]
        unless ignore_synonyms
          @query_names+=@source_item.synonyms(true,false)
        end
        if use_words
          @all_words = []
          @query_names.each do |qn|
            @all_words+=qn.split(" ")
          end
        else
          @all_words = @query_names
        end

        @q_fmts = @all_words.map {|val| "%#{val.downcase}%" }

        if ignore_tags
          @images=Source.select(sel_sql)
          .no_topics #source_topics have item_id = null
          .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id").ors(@q_fmts)
          .limit(@limit)
        else
          @images+=Source.select(sel_sql)
          .no_topics #source_topics have item_id = null
          .joins("LEFT JOIN source_topics ON source_topics.source_id = sources.id").ors(@q_fmts)
          .limit(@limit)
        end

        @sql = @images.clone.to_sql
        #matched = []
        #newdata = nil
        #q_fmts.each do |q|
        #  newdata+=(Source.select("DISTINCT(sources.id),sources.*,urlToImage as image_url").matching(q,2))
        #end
        #newdata.limit(100)

  #      matched = News.article_images query_names
        #images+=matched
      end
    end

    if params[:test]

    else
      if request.post?
        render :json=>{:photos=>@images}
      end
    end

  end

  	protected

    def set_otype
      @otype = "sources"
    end
   
	  def tag_params
	  	@source_id = params[:source_id].to_i
	  	@item_name = params[:title].strip if params[:title]
	  	@item_id = (params[:item_id].to_i == 0) ? nil : params[:item_id].to_i # || nil
	  	@source = Source.find_by(id: @source_id)
	  end

    def permitted_parameters
    	params.require(:source).permit(:title,:org_id,:url)
  	end

  	def load_entities
	    @sources = Source.limit(100)
	    @source = Source.find(params[:id]) if params[:id]
	    @user = current_user
  	end

    def load_feed_report
      @unrated_by_me = unrated_by_me
      @unrated = unrated
    end

    def recent_votes
      #this array could be massive
       ActsAsVotable::Vote.where("voter_type = ? AND voter_id = ? AND votable_type = ? AND created_at > ?","User",current_user.id,"Source",7.days.ago).pluck(:votable_id)
    end

    def custom_unrated_by_me_guessed user #, label = nil, recency_key = 0
      
      guessed_interest = GuessScope.where(user_id:user.id,target_type:"Source",accurate:nil)
      .order("score DESC").limit(100)
      .where("score > ?",5)
      .pluck(:target_id)

      Source.select("sources.*")
      .where(id: guessed_interest)
      .where.not(id: recent_votes)
    end

    def custom_unrated_by_me query_name = :blended, label = nil, recency_key = 0
      Source.select("sources.*").customsort(query_name,label: nil,recency_key: recency_key)
      .where.not(id: recent_votes)
    end

    def recent_guesses target_ids, query_name = :blended, label = nil, recency_key = 0
      Source.select("sources.*").customsort(query_name,label: nil,recency_key: recency_key)
      .where(id:target_ids)
      #.where.not(id: recent_votes)

    end

    def unrated_by_me
      @data = Source.where.not(id: recent_votes)
      .where("created_at > ?",2.days.ago)
    end
    def unrated
      @data = Source.joins("LEFT OUTER JOIN votes ON votable_id = sources.id AND votable_type = 'Source'")
      .where("votable_id is NULL")
      .where("sources.created_at > ?",2.days.ago)
    end

    def classify_sources sources

      ga = GoogleAnalyze.new
      sources.each do |source|
        source.google_classify! entities: true, min_salience: 0.01, ga: ga unless source.title.blank?
      end

=begin
    aylien = Summarize.new

    sources.each do |source|
      @input = source.title + " " + source.description
      #@input = 'Victoria reports 41 new coronavirus cases, the state\'s lowest single-day increase in cases since June. It comes after the State Government unveiled its "roadmap to recovery" outlining four phases Victoria will progress through as restrictions are lifted.'
      
      @classify = aylien.classify! @input
      @classify[:categories].each do |row|
          item = Item.find_by(iptc_subject_code:row[:code].to_i)
          SourceTopic.create(source_id:source.id,item_id:item.id,score:row[:confidence]) unless SourceTopic.where(source_id:source.id,item_id:item.id).exists?
          
          #TODO: add entities from aws Comprehend

      end
    end
=end

  end

end