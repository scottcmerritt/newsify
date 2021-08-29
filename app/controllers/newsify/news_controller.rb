module Newsify
  class NewsController < ApplicationController
    # this is a public url to permit background processes to trigger imports via GET
    # TODO: consider adding throttling, caching and authentication
    def import_start

      terms = Newsify.article_import_terms.sample(2)
      terms.push "headlines" unless terms.include? "headlines"
      terms.each do |term|
        Import.start_import({:max_pages=>1,:page=>1,:q=>term},0, logger, api_key:ENV["NEWS_API_KEY"])
      end

=begin
      similar, sources, new_group_ids = Classify::Similar.group_similar! true, true
      puts "#{new_group_ids.length} new article groups"

      # TODO: get unique articles, those grouped (just get 1)
      Newsify::Source.unique_sources.each_with_index do |source,index|
        puts "Classifying and summarizing article ##{index}"
        Classify::Summarize.from_sources source
        source.google_classify!(entities:true,full_scan:true)
      end
=end
      render json:{status:true, terms: terms}
    end

    def index

    end

    def search
      @q = params[:q]
      @page = params[:page] ? params[:page].to_i : 1

      query = @q.downcase.strip
      prepped = "%#{query}%"
      @labeled = Source.select("sources.*")
      .where("lower(title) LIKE ?",prepped).page(@page)

      @show_fields = {articles:true,children:true}
      @items = Item.select("items.*")
      .where("lower(name) LIKE ?",prepped).page(@page)    

      render "/newsify/shared/search"
    end

    # LOG OF their activity within the newsify engine/plugin
    def activity

    end

    def profile
      @user = User.find(params[:id])
    end

    def admin

      redirect_to root_path if current_user.nil?


        # GET /info/sources
  
      within_days = 2
      
      guess_interest if params[:guess]

      @info = {:rated=>current_user.rated(Newsify::Source),:ratings=>current_user.ratings(Newsify::Source)}
      @info[:raters] = ActsAsVotable::Vote.select("voter_id").where("voter_type = ?","User").distinct(:voter_id).count
      @info[:sources] = Source.count
      @info[:sources_recent] = Source.where("created_at > ?",within_days.days.ago).count

      @info[:sources_grouped] = Source.where("NOT group_id is null").count
      @info[:sources_recent_grouped] = Source.where("created_at > ? AND NOT group_id is null",within_days.days.ago).count
      @info[:filter] = {within_days: within_days}

      render "newsify/admin/index"
    end

      # /manage/guess/interest
    def guess_interest

      guess_scope_key = "interesting"

      # get recently classified sources
      
      #TODO: optionally EXCLUDE articles they ALREADY rated

      if params[:back_check_guesses]


      end

      @targets = Import.recent.limit(5).each.collect {|import| import.import_sources.each.collect{|row| row.source} }.flatten

      @targets = @targets.sort_by {|target| -target.guess_scope(scope:guess_scope_key).score}
      # last.import_sources.each.collect{|row| row.source}
      if params[:run]
        @sources = Source.guess_interest! current_user, @targets
      end
    end

    def calc_fame
      if params[:run]
        ItemUtil.calc_fame!
      end

      @items = Item.all.order("relevance DESC").page(params[:page]).per(20)
    end

    # update all interest scores
    # if params[:classify] set, get 3 downvotes (not interesting) and classify them using GoogleAnalyze
    # if params[:run], calc interests for the current_user
    def calc_interests
      User.update_all_interest_scores!

      # get
      user = current_user
      resource_type = Source

      @limit = 3
      @downvotes = user.find_down_votes_for_class(resource_type, {vote_scope:"interesting"})
      .limit(@limit).order("created_at DESC")

      ga = GoogleAnalyze.new
      user = current_user

      @classified = []
      #source=Source.find(4258)
      #source.google_classify! true, 0.3, ga

      if params[:classify]
      @downvotes.each do |vote|
        if vote.votable.topics.length == 0
          #vote.votable.google_classify! true, 0.3, ga
          source = Source.find(vote.votable.id)
          source.google_classify! entities: true, min_salience: 0.01, ga: ga

          @classified.push source.id
        end
      end
      end


      if params[:run]
        ItemInterest.calc_interests! current_user, remove: true
      end

      @interests = ItemInterest.by_user current_user, limit: 100
      @disinterests = ItemInterest.by_user current_user, limit: 100, order: :asc
      @results = ItemInterest.by_user current_user, limit: 10, order: :desc, query: params[:q] unless params[:q].nil?

      current_time = 40.minutes.ago
      @demo = ItemInterest.where(resource_type:"Source".to_s,user_id:current_user.id).where("created_at < ?",current_time)

    end
 
    
  end
end
