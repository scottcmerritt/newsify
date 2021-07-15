module Newsify
	class Cache < Feedbacker::Cache

		def self.import_pct import_id
			key = "import_pct::#{import_id}"
			return Newsify::Cache.get_obj key
		end
		def self.save_import_pct! import_id, val
			cache_key = "import_pct::#{import_id}"
			Newsify::Cache.set_obj cache_key, val #, nil, 500
		end
	end
end