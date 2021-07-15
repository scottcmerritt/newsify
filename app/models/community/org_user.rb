module Community
	class OrgUser < ActiveRecord::Base
		belongs_to :org, class_name: 'Community::Org'
		belongs_to :user

		include MembershipUser

		
	end
end