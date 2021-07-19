module Newsify
	class SummarySourcesController < ApplicationController

		#def self.controller_path
	    #  "news/summary_sources" # change path from app/views/ideas to app/views/tasks
	  	#end

		def create
			@source = Source.find_by(id: params[:source_id])
			unless @source.nil?
				summary = Summary.create(title:params[:title],createdby:current_user.id)
				SummarySource.create(source_id:@source.id,summary_id:summary.id)
			end

			respond_to do |format|
	        format.html {render "index"} #{ render "/sounds/browse"}
	        format.js do 
	        	@notice = "Summary added"
	        	render "list.js"
	        end
	        format.json {render :json => {data: @sources}}
	    end

		end

	end
end