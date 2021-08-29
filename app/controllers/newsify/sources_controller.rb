module Newsify
  class SourcesController < ApplicationController
    require "custom_sort" #phasing out
    require "sortify"
    include Newsify::ClassifyNews, Newsify::NewsGeneral
    include Community::LabeledData

    before_action :setup_pager
    before_action :set_source, only: [:show,:edit,:opinions]

#      before_action :load_entities, only: [:show,:edit,:update]
#  before_action :load_feed_report, only: [:info,:index,:mine,:start,:scroll,:report,:labeled,:my_interests]

    before_action :get_links
    before_action :set_otype
    before_action :load_feed_report, only: [:index,:labeled,:mine,:scroll,:report]

    skip_before_action :verify_authenticity_token, only: [:index,:labeled]

    def new
      @source = Source.new
    end

    def edit

    end
    
    def index
      @labels =  ["saved"] + @labels
      #Newsify::Cache.set_obj "my_test_key", "hello"
      #@cache_result = Newsify::Cache.get_obj "my_test_key"

      news_feed = Newsify::Feed.new(model:Newsify::Source,params:params,load:true,defaults:false)
      @labeled = news_feed.data
    end

    # TODO: implement add_friend_filter
    # TODO: debug this A LOT MORE
    def labeled
      @labels =  ["saved"] + @labels

      @sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
      news_feed = Newsify::Feed.new(model:Newsify::Source,params:params,load:false,sort_by:@sort_by)

      @otype = "source"
      if params[:label] == "saved" && @label = params[:label]
        @labeled = news_feed.saved_data current_user
      else
        @recent_relevance, @label, @sort_order = news_feed.filter!
        @js_url = "/labeled/sources/#{@label}.js"

        @labeled = news_feed.data

      end
      render "index"
    end

    # recent sources, exclude grouped
    def grouped
      @sources = Source.unique_sources import_id: params[:import_id] ? params[:import_id].to_i : nil
      @excluded = []

      respond_to do |format|
        format.html {render "grouped"} #{ render "/sounds/browse"}
        format.js { render "grouped.js" }
        format.json {render :json => {sources:@sources}}
      end
    end

    def show

      # do fake votes from 20 users
      do_fakevote! if params[:fakevote] && is_admin?


      impression = impressionist(@source, "",{},{})
      do_summarization! if params[:summarize]

      @new_comment    = Comment.build_from(@source, current_user.id, "")
      @classified = @source.google_classify!(entities:params[:entities],full_scan: params[:fullscan]) if params[:gc]

    end

    def opinions

    end
    def imported

      @labeled = Source.joins("LEFT JOIN import_sources ON sources.id = import_sources.source_id")
      .where("import_id = ?",params[:import_id]).page(@page)
      render "index"

    end
    def import

#     Import.auto_import!
#    Similar.group_similar!
  
      #q = "music"
      #:page, :q
      @terms = Newsify.article_import_terms

      @error_count = 0

      if params[:news] && params[:news][:term]
        terms = [params[:news][:term]] #["dating"] #["tech"] #["dating"] #[nil,"tennis","soccer","summer","open source","software","dating","startup","acquired","music","entrepreneur","tech","business","education","fullerton","orange county","california"]
        terms.each do |term|
          Import.start_import({:max_pages=>1,:page=>1,:q=>term},current_user.id, logger, api_key:ENV["NEWS_API_KEY"])
        end

        redirect_to newsify.sources_import_path(step:2) #sources_path
      end
      @imports = Newsify::Import.order("id desc").limit(50)
      @step = params[:step].to_i
  end

    private

    def target_type
      "Newsify::Source"
    end
    
    def set_otype
      @otype = "sources"
    end

    def set_source
      @source = Source.find_by(id:params[:id])
    end

    def setup_pager
      @page = params[:page] ? params[:page].to_i : 1
      @page = 1 if @page < 1
    end

    def do_summarization!      
      @testing = 123
      if params[:clean]
        @purging = @source.purge_duplicate_topics
      end

      if params[:summarize] 
        summary_count = @source.summary_count
        if summary_count == 0
          @summarize_result = Classify::Summarize.from_sources @source
        end
      end

      source_hash_string = {:site=>"localhost",:table=>"sources",:id=>@source.id,:user_id=>0}.to_json.to_s
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



  # MOVE THIS STUFF ELSEWHERE (organize it)

    def load_feed_report within_days: 2
      @unrated_by_me = unrated_by_me
      @unrated_by_all = Source.unrated within_days: within_days
    end

    def recent_votes within_days: 7
      #this array could be massive
       ActsAsVotable::Vote.where("voter_type = ? AND voter_id = ? AND votable_type = ? AND created_at > ?","User",current_user.id,target_type,within_days.days.ago).pluck(:votable_id)
    end

    def custom_unrated_by_me_guessed user #, label = nil, recency_key = 0
      
      guessed_interest = Community::GuessScope.where(user_id:user.id,target_type:target_type,accurate:nil)
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

    def unrated_by_me within_days: 2, votes_within_days: 7
      @data = Source.where.not(id: recent_votes(within_days:votes_within_days))
      .where("created_at > ?",within_days.days.ago)
    end

    def do_fakevote! default_vscope: "learnedfrom"

      User.select("*").limit(20).each do |user|

        if true #rand(0..1) == 0
          vparams = {user: user,otype:"source",oid:@source.id}
          #@voting = Community::Voting.new(params:vparams,user:user,is_admin:false,logger:logger)
          #@voting.log_vote! if rand(0..3) == 0

          vparams[:vscope] = params[:label] || default_vscope
          @voting = Community::Voting.new(params:vparams,user:user,is_admin:false,logger:logger)

          @voting.log_vote! if true #rand(0..3) == 0
        end

      end

      end



  end
end