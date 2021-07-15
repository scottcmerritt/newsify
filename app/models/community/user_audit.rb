module Community
	class UserAudit < ActiveRecord::Base
		self.table_name = "user_audits"

		acts_as_votable #cacheable_strategy: :update_columns
		acts_as_voter
		include Community::IconUtil

		def title
			"A person review: #{self.vote.votable.class.name} ID: #{self.vote.votable.id} VID: #{self.vote.id}"
		end
		def otype_guessed
			"user_audit"
		end

		def user
			User.find(self.user_id) #ActsAsVotable::Vote.where("id = ?",self.vote_id).first
		end

		def voted_by
			self.vote.voter.id unless self.vote.nil?
		end
		def voted_by_name
			self.vote.voter.display_name_public
		end
		def vote_exists?
			!self.vote.nil?
		end

		def votable_type
			self.vote.votable_type
		end
		def votable_id
			self.vote.votable_id
		end
		def vote_created_at
			self.vote.created_at
		end

	end
end