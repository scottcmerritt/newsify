module Newsify
	class ImportSource < ActiveRecord::Base
		self.table_name = "import_sources"
		#include ActiveModel::Model
		belongs_to :import, inverse_of: :import_sources
		def source
			Source.find_by(id:self.source_id)
		end
	end
end