module Newsify
	class AuthorsController < ApplicationController
	#before_action :authenticate_user
		
		def index
	  	  @authors = Author.all.page(params[:page]).per(20)
		end

		def show
			@author = Author.find_by(id: params[:id])

			@author.cache_orgs!(archive: (params[:fullcache] ? true : false)) if params[:cache]

			@from_cache = @author.respond_to?(:orgs) && @author.respond_to?(:orgs_cached) && !@author.orgs_cached.nil?
			if @from_cache
				both = @author.orgs(both:true)
				@orgs = both[:active]
				@orgs_inactive = both[:inactive]
			else
				@orgs = @author.author_orgs.where(is_active:true)
				@orgs_inactive = @author.author_orgs.where(is_active:false)
			end
		
		end

	end
end