module Community
	class VoteCache < ActiveRecord::Base
		def self.model_name
      		ActiveModel::Name.new("Community::VoteCache", nil, "VoteCache")
    	end

	end
end