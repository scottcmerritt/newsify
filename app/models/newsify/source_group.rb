class SourceGroup < ActiveRecord::Base
	self.table_name = "source_groups"
	
	def self.distinct_groups
		select("DISTINCT(source_id)").count
	end

end