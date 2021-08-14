require "newsify/version"
require "newsify/engine"

require 'newsify/configure'

module Newsify
  # Your code goes here...
  extend Configure

  def newsify(options = {})


  end

end


require "community/wiki_util"
require "community/concerns/votes/labels/ad"
require "community/concerns/votes/labels/clickbait"
require "community/concerns/votes/labels/english"
require "community/concerns/votes/labels/fun"
require "community/concerns/votes/labels/funny"
require "community/concerns/votes/labels/interesting"
require "community/concerns/votes/labels/learnedfrom"
require "community/concerns/votes/labels/quality"
require "community/concerns/votes/labels/spam"

require "community/concerns/votes/labels"

require "community/concerns/icon_util"
require "community/concerns/membership"
require "community/concerns/membership_user"
require "community/concerns/vote_stats"
require "community/concerns/vote_cacheable"
require "community/concerns/user_utility"
require "community/concerns/user_community"

require "community/concerns/labeled_data"


#%i[VoteLabelSpam VoteLabelQuality VoteLabelInteresting VoteLabelLearnedfrom VoteLabelFun VoteLabelFunny VoteLabelAd VoteLabelClickbait VoteLabelEnglish]


require "newsify/text_util"
require "newsify/stats/org_custom"
require "newsify/import_source"
require "newsify/import"
require "newsify/news_general"
require "newsify/news_manager"

require "newsify/news_categories"
require "newsify/entity_row"
require "newsify/google_analyze"

require "newsify/goog_news_categories"