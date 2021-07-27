module Newsify
class SummariesController < ApplicationController
	include Newsify::NewsGeneral
  	before_action :get_links
  	before_action :set_otype

	before_action :load_entities, only: [:index,:show,:edit,:update]

	#def self.controller_path
    #  "news/summaries" # change path from app/views/ideas to app/views/tasks
  	#end

	def index
		@room = Room.find_by(id:params[:room_id]) if defined?(Room)
		@summaries = Summary.all
		@query = "%#{params[:q]}%" if params[:q]

		@summaries = @summaries.where("LOWER(title) LIKE ?",@query) unless @query.nil?
		@summaries = @summaries.order("id DESC")

		@summaries = @summaries.page(params[:page])
		#@summary_sources = SummarySource.all
	end

	 def labeled
	    @sort_by = ["cached_weighted_score","cached_weighted_average","cached_weighted_quality_average"]    
	    @sort_order = "DESC"
	    
	    @label = (@mod_labels+@labels).include?(params[:label]) ? params[:label] : nil

	    @order_text = @sort_by[0]

	    @order_text = "cached_weighted_#{@label}_average" unless @label.nil? #  "cached_weighted_score"

	    @summaries = Summary.joins("LEFT JOIN vote_caches ON vote_caches.resource_id = summaries.id")
	    .where("vote_caches.resource_type = ?","Summary")
	    .order("#{@order_text} #{@sort_order}").page(params[:page])

		render "index"
	end

	def new
		@sources = Source.where("id IN (?)",params[:sources])
		@summary = Summary.new
		@summary.source_ids = @sources.pluck(:id) unless @sources.nil?
	end
	
	def show
		@summary = Summary.find(params[:id])

#		require 'diffy'
		
		# :include_diff_info=>false

		@diffed = Diffy::Diff.new(@summary.paper_trail.previous_version.title, @summary.title,:include_diff_info=>false).to_s(:html) unless !@summary.respond_to?(:paper_trail) || @summary.paper_trail.previous_version.nil?

		@custom_timer = {}
		st = Time.now
		refresh = (params[:refresh].to_s == "true")
		
		@topics = @summary.topics 100, refresh, true
		@custom_timer["page_load"] = (Time.now-st)
	end
	def edit

	end

	def update
		if @summary.update(permitted_parameters)
	      flash[:success] = "Summary #{@summary.title} was updated successfully"
	      redirect_to @summary
	    else
	      render :new
	    end
	  end


	  def destroy
	  	@summary = Summary.find(params[:id])
	  	@summary.destroy
	  	redirect_to summaries_path
	  end


	def create
		@summary = Summary.new permitted_parameters

		@summary.createdby = current_user.id

		if @summary.save
			 flash[:success] = "Summary #{@summary.title} was created successfully"
      
		      #@user = User.find(1)
		      #RoomChannel.broadcast_to @user, @user

		      redirect_to summaries_path

		else
			render :new
		end
	end

	protected
	def set_otype
      @otype = "summaries"
    end

	def permitted_parameters
    	params.require(:summary).permit(:title,:source_ids,:icon_css)
  	end

  	def load_entities
	    @summaries = Summary.limit(100)
	    @summary = Summary.find(params[:id]) if params[:id]
	    @user = current_user
  	end
end
end