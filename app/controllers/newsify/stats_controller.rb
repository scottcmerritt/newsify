module Newsify
  class StatsController < ApplicationController
    # THIS IS A PUBLIC controller (or now)
    skip_before_action :authenticate_user!

    def index
      render json: site_stats
    end

    private

    def site_stats
      {
        users:10,
        articles:350,
        favorites: {articles:site_favorites(:articles),topics:site_favorites(:topics)}
       }
    end

    def site_favorites type

      case type
      when :articles
        ["Article 1","Article 2"]
      when :topics
        ["Topic 1","Topic 2"]
      end

    end

  end
end