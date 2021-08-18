module Newsify
  class SourcesController < ApplicationController
    require "custom_sort" #phasing out
    require "sortify"
    include Newsify::ClassifyNews, Newsify::NewsGeneral
    include Community::LabeledData

    before_action :setup_pager
    before_action :set_source, only: [:show, :opinions]

#      before_action :load_entities, only: [:show,:edit,:update]
#  before_action :load_feed_report, only: [:info,:index,:mine,:start,:scroll,:report,:labeled,:my_interests]

    before_action :get_links
    before_action :set_otype
    before_action :load_feed_report, only: [:index,:labeled,:mine,:scroll,:report]

    skip_before_action :verify_authenticity_token, only: [:index,:labeled]


    def index
      @labels =  ["saved"] + @labels
      #Newsify::Cache.set_obj "my_test_key", "hello"
      #@cache_result = Newsify::Cache.get_obj "my_test_key"

      if params[:oid]
        @labeled = Source.select("sources.*").joins(:source_topics) 
        @labeled = @labeled.where(source_topics: {item_id: params[:oid]})
      elsif params[:author_id]
        @labeled = Source.select("sources.*").joins("LEFT JOIN source_authors ON source_authors.source_id=sources.id")
        @labeled = @labeled.where("source_authors.author_id = ?",params[:author_id])
      elsif params[:import_id]
        @labeled = Source.select("sources.*").joins("LEFT JOIN import_sources ON sources.id = import_sources.source_id")
        .where("import_id = ?",params[:import_id])
      else
        @labeled = Source.select("sources.*")
      end
      @labeled = @labeled.where(org_id:params[:org_id]) if params[:org_id]

      @labeled = @labeled.order("sources.created_at DESC")
      @labeled = @labeled.page(@page).per(20)
    end

    def labeled
      @labels =  ["saved"] + @labels

      @otype = "source"
      if params[:label] == "saved"
        @label = "saved"
        @labeled =  current_user.favorited_by_type(target_type).page(params[:page])
      else
        @sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
        @sort_order = "DESC"


        setup_label_sort
        setup_time_decay
        @js_url = "/labeled/sources/#{@label}.js"

        #Source.where("title = ?","Dated test article").destroy_all

        setup_labeled_data
        #add_friend_filter
        add_order_by
=begin
        @label = (@mod_labels+@labels).include?(params[:label]) ? params[:label] : nil

        @order_text = @sort_by[0]

        @order_text = "cached_weighted_#{@label}_average" unless @label.nil? #  "cached_weighted_score"

        @labeled = Source.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = sources.id")
        .where("vote_caches.resource_type = ?","Newsify::Source")
        .order("#{@order_text} #{@sort_order}").page(params[:page]).per(10)
=end
      end
      render "index"
    end

     def labeled_old
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



  end
end