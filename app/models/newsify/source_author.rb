module Newsify
	class SourceAuthor < ActiveRecord::Base
		self.table_name = "source_authors"
		belongs_to :source
		belongs_to :author
	end
end
