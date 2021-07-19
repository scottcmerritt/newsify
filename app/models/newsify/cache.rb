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


		## CLASSIFICATION STATUS INFO	
		def self.start_classify key, data, cache_expiration = 60000
			rkey = "classifyStatus_#{key}"
			$redis.set(rkey,data.to_json.to_s,{:ex=>cache_expiration})
	#		$redis.set(rkey,Marshal.dump(data),{:ex=>cache_expiration})
		end

		def self.set_classify_status key, data, cache_expiration = 60000
			rkey = "classifyStatus_#{key}"
			#$redis.set(rkey,data.to_json.to_s,{:ex=>cache_expiration})
			Newsify::Cache.set_obj rkey, data.to_json.to_s, nil, cache_expiration
			#$redis.set(rkey,Marshal.dump(data),{:ex=>cache_expiration})
		end
		
		#used to return importing status {:page,:page_size,:status}
		def self.check_classify_status key, logger = nil
			rkey = "classifyStatus_#{key}"
			raw_redis = Newsify::Cache.get_obj rkey #$redis.get(rkey)

			logger.debug "raw_redis: #{raw_redis}" unless logger.nil?
			if raw_redis.blank?
				return nil
			else
				return JSON.parse(raw_redis) #Marshal.load(raw_redis) #.to_json
			end
		end

	end
end