module Newsify
class BackgroundProcess

	def initialize(attributes={})
		@start_time = Time.new
		@page_load_time = 0
		@params = attributes[:params]

		@custom_timer = {}
		@cache_stats = {}

		@logger = attributes[:logger] || nil
		@log = []
		@status_key = "classifying_progress"
		@status_data = {:page=>1,:page_size=>100,:status=>"training",:items=>0,:total=>0}
	end

	def params
		@params
	end
	def log
		@log
	end
	def page_load_time
		@page_load_time
	end

	def custom_timer
		@custom_timer
	end
	def cache_stats
		@cache_stats
	end

	def status_start items = 100, title="classifying Items"
		@status_data[:total] = items
		@status_data[:status] = title
        Cache.start_classify @status_key,@status_data
	end
	def status_item_count items = 100
		@status_data[:total] = items
		@status_data[:items] = 0
	end
	def status_incr num
		unless @status_data[:items].nil?
			@status_data[:items]+=num
			#TODO: add if (@status_data[:items] % 10) == 0
			status_update
		end
	end

	def status_update new_status=nil
		if @status_data.nil?
			@status_data = Cache.check_classify_status @status_key
		end
		
		unless new_status.nil?
			@status_data[:status] = new_status
		end
		unless @status_data.nil?
        	Cache.set_classify_status @status_key,@status_data
    	end
	end
end
end