module Newsify
	class AuthorsController < ApplicationController
	#before_action :authenticate_user
		


		def index
	  	  @authors = Author.all.page(params[:page]).per(20)
		end

		def show
			@author = Author.find_by(id: params[:id])
		end

	end
end