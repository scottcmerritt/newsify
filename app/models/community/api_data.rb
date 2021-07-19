module Community
class ApiData

	def self.proxy_post page,params,root_url = "http://0.0.0.0:3001",use_ssl=true,logger=nil
		return ApiData.post page,params,root_url,use_ssl,logger
	end

	def self.proxy_get page,params,root_url = "http://0.0.0.0:3001",use_ssl=true,logger=nil
		return ApiData.get page,params,root_url,use_ssl,true,logger
	end

	def self.post page,params,root_url = "http://0.0.0.0:3001",use_ssl=true,logger=nil
		
		if ["events","visits"].include? page
			url = page
		end

		full_url = (root_url+url)
		logger.debug "url: #{full_url}" unless logger.nil?
		logger.debug "params: #{params}" unless logger.nil?
		output = self.make_post_req full_url,params,logger, use_ssl
		return output
	end
	

	def self.get page,params,root_url = "http://0.0.0.0:3006/",use_ssl=true,raw_data=false,logger=nil
		
		if true || ["events","visits"].include?(page)
			url = page
		end

		full_url = (root_url+url)
		logger.debug "url: #{full_url}" unless logger.nil?
		logger.debug "params: #{params}" unless logger.nil?
		output = self.make_get_req full_url,params,logger, use_ssl, raw_data
		return output
	end

	def self.make_post_req url,params,logger=nil,use_ssl=false, raw_data=true
	    
	    #TODO: remove params[:post_url], it is not needed in the params

	    output = ""
	    require 'net/http'
	    require 'json'
	    begin
	    	logger.debug "ahoy::debug posting to: #{url}" unless logger.nil?
	        uri = URI(url)
	        http = Net::HTTP.new(uri.host, uri.port)
	        req = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json',  
	          'Authorization' => 'XXXXXXXXXXXXXXXX'})
	        http.use_ssl = use_ssl 

	        req.body = params.to_json
	        res = http.request(req)
	        output+=res.body
	        logger.debug res unless logger.nil?
	        logger.debug res.body unless logger.nil?
	        #output+= "response #{res.body}"
	        #output+= JSON.parse(res.body)
	    rescue => e
	        logger.debug "ERROR calling: #{url}: #{e}" unless logger.nil?
	        #puts "failed #{e}"
	    end
	    if raw_data
		    return output
		else
			return JSON.parse(output)
		end
  	end

  	def self.make_get_req url, params, use_ssl=false, raw_data=false,logger=nil

		begin
		param_txt = "?"
		joiner = ""
		params.each_pair do |k,v|
			param_txt+="#{joiner}#{k}=#{v}"
			joiner="&"
		end
		full_url = url+param_txt

		_result = self.get_data(full_url, use_ssl)
		if raw_data
			return _result
		else
			return JSON.parse(_result)
		end
		rescue => e
			return nil
		end
	end

	def self.get_data url, use_ssl = false

		require 'open-uri'
		if use_ssl
			req = URI.open(url)
		else
			req = URI.open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
		end
		return req.read
	end

  	def self.do_test_track

  		url = "http://0.0.0.0:3003/add/log"
#  		?guid=d3bae71f-6871-42d8-8041-eacf78fbbfba&token=gGIC7hVLlU6deKgrzr4NKg"
  		_params = {:guid=>"d3bae71f-6871-42d8-8041-eacf78fbbfba",:token=>"gGIC7hVLlU6deKgrzr4NKg"}
  		ApiData.make_get_req url,_params,nil

  	end

end
end