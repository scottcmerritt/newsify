module Newsify
  class ApplicationController < ::ApplicationController # ActionController::Base # 
    before_action :set_engine_name!
    #before_action :set_paper_trail_whodunnit
    #helper Feedbacker::Engine.helpers
    helper_method :newsify? 
    def newsify?
      true
    end

    def set_engine_name!
      @engine_name = "newsify"
    end


  end
end
