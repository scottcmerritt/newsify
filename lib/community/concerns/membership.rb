module Community
module Membership

  # NOTE: this next line was commented out, not sure if that was intentional
  extend ActiveSupport::Concern


  	def add! user, approved_by
		self.join! user
		self.member_approve! user, approved_by
	end

	def join! user
		join_status = self.can_join? user
		if join_status.nil?
			# they are already a member

		elsif join_status
			# they can join
			if self.relationship_with? user
				# rejoin
				self.applicant_relationship.removed = false
				self.applicant_relationship.is_pending = self.approve_members
				self.applicant_relationship.approved = !self.approve_members
				self.applicant_relationship.save
			else
				ou = Community::OrgUser.new(:user_id=>user.id,:org_id=>self.id)
				ou.is_pending = self.approve_members
				ou.approved = !self.approve_members


				ou.save
			end
		else
			# they can't join

		end
	end

	def leave! user
		self.check_relationship! user
		if self.is_member? user
			self.applicant_relationship.removed = true
			self.applicant_relationship.removed_by = user.id
			self.applicant_relationship.save
		end
	end

	def member_approve! user, approved_by
		self.check_relationship! user if self.applicant!=user
		if self.relationship_with? user
			self.applicant_relationship.removed = false
			self.applicant_relationship.approved = true
			self.applicant_relationship.approved_by = approved_by.id unless approved_by.nil?
			self.applicant_relationship.approved_at = DateTime.now
			self.applicant_relationship.is_pending = false
			self.applicant_relationship.save
		end
	end

	def member_deny! user, approved_by
		self.check_relationship! user if self.applicant!=user
		if self.relationship_with? user
			self.applicant_relationship.removed = true
			self.applicant_relationship.removed_by = approved_by.id
			self.applicant_relationship.removed_at = DateTime.now
			self.applicant_relationship.is_pending = false
			self.applicant_relationship.save
		end
	end


		# check the group, is it joinable?
		# check to see if they're a member or former member
		# call relationship
		
		def can_join? user
			return false if !self.joinable?
			return true if !self.relationship_with? user

			# if we are here, applicant and applicant_relationship are set, and it is a group (that they have a relationship with)

			return false if (self.applicant_relationship.pending? || self.applicant_relationship.kicked_out?)
			return true if self.applicant_relationship.left_group?

			return nil # they are a member
		end
		def is_pending? user
			self.check_relationship! user if self.applicant!=user
			self.applicant_relationship.nil? ? false : self.applicant_relationship.pending?
		end
		def is_member? user
			self.check_relationship! user if self.applicant!=user
			self.applicant_relationship.nil? ? false : (self.applicant_relationship.member? ? !self.is_pending?(user) : false)
			#OrgUser.exists?(:user_id=>user.id,:org_id=>self.id,:removed=>false,:pending=>false)
		end

		def check_relationship! user
			self.applicant = user
			self.applicant_relationship = Community::OrgUser.find_by(:user_id=>user.id,:org_id=>self.id)
		end
		def relationship_with? user
			self.check_relationship! user if self.applicant!=user
			
			return !self.applicant_relationship.nil?
			#OrgUser.exists?(:user_id=>user.id,:org_id=>self.id)
		end


end
end