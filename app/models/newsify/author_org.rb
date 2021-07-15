module Newsify
	class AuthorOrg < ActiveRecord::Base
		self.table_name = "author_orgs"
		belongs_to :org, class_name: 'Community::Org'
		belongs_to :author
	end
end