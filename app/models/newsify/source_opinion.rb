module Newsify
	class SourceOpinion < ActiveRecord::Base
		self.table_name = "source_opinions"
		belongs_to :source
		belongs_to :user
	end
end