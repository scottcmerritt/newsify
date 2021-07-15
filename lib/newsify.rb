require "newsify/version"
require "newsify/engine"

module Newsify
  # Your code goes here...
end



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


#%i[VoteLabelSpam VoteLabelQuality VoteLabelInteresting VoteLabelLearnedfrom VoteLabelFun VoteLabelFunny VoteLabelAd VoteLabelClickbait VoteLabelEnglish]


require "newsify/stats/org_custom"
require "newsify/import_source"
require "newsify/import"
require "newsify/news_general"

require "newsify/google_analyze"