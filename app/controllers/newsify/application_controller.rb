module Newsify
  class ApplicationController < ::ApplicationController # ActionController::Base # 
    before_action :set_engine_name!
    #helper Feedbacker::Engine.helpers
    helper_method :newsify? 
    def newsify?
      true
    end

    def set_engine_name!
      @engine_name = "newsify"
    end

    def index
      render json: "Here is the news plugin"

    end
  end
end
