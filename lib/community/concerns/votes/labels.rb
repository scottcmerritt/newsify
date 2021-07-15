module Community
  module Votes
    module Labels
      extend ActiveSupport::Concern
      # spam, quality, interesting, learnedfrom, fun, funny, ad, clickbait, english
#      include VoteLabelSpam, VoteLabelQuality, VoteLabelInteresting, VoteLabelLearnedfrom, VoteLabelFun, VoteLabelFunny, VoteLabelAd, VoteLabelClickbait, VoteLabelEnglish
      include Votes::Labels::Spam,Votes::Labels::Quality,Votes::Labels::Interesting,Votes::Labels::LearnedFrom,Votes::Labels::Fun,Votes::Labels::Funny,Votes::Labels::Ad,Votes::Labels::Clickbait,Votes::Labels::English

    end
end
end