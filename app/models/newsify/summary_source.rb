module Newsify
class SummarySource < ActiveRecord::Base
	self.table_name = "summary_sources"
	belongs_to :summary
	belongs_to :source
end
end
