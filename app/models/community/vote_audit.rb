module Community
	class VoteAudit < ActiveRecord::Base
		acts_as_votable #cacheable_strategy: :update_columns
		acts_as_voter
		include IconUtil

		def title
			"An opinion: #{self.vote.votable.class.name} ID: #{self.vote.votable.id} VID: #{self.vote.id}"
		end
		def otype_guessed
			"vote_audit"
		end

		def vote
			ActsAsVotable::Vote.where("id = ?",self.vote_id).first
		end

		def voted_by
			self.vote.voter.id unless self.vote.nil?
		end
		def voted_by_name
			self.vote.nil? ? "No vote" : (self.vote.voter.respond_to?(:display_name_public) ? self.vote.voter.display_name_public : "Opinion audit")
		end
		def vote_exists?
			!self.vote.nil?
		end

		def votable_type
			self.vote.votable_type unless self.vote.nil?
		end
		def votable_id
			self.vote.votable_id unless self.vote.nil?
		end
		def vote_created_at
			self.vote.created_at unless self.vote.nil?
		end

	end
end