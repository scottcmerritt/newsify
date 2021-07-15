module Community
module MembershipUser

  # NOTE: this next line was commented out, not sure if that was intentional
  extend ActiveSupport::Concern

  	def pending?
		self.is_pending == true
	end
	def left_group? 
		self.removed && self.removed_by == self.user_id
	end
	def kicked_out?
		self.removed && self.removed_by != self.user_id
	end
	def member?
		!(self.removed || self.is_pending)
	end
end
end
