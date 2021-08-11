module Community
class WikiUtil
	def self.search query
		root_url = "https://en.wikipedia.org"
	    page = "/w/api.php?action=opensearch&search=#{query}&limit=30&namespace=0&format=json&srlimit=30"
	    data = ApiData.get page, {},root_url
	end

	def self.process_search data
		json_data = JSON.parse(data)
		names = json_data[1]
		links = json_data[3]

		res = []
		names.each_with_index do |name,index|
			res.push({name:name,page:links[index]})
		end
		res


	end

	
	def self.wiki_extract_links content
		temp = content.split("[[")
		# {amazon]], blah blah}, {amazon2]], blah}
		options = []
		temp.each do |t|
			temp2 = t.split("]]")
			options.push temp2[0]
		end

		return options
	end


	def self.wiki_info_by_url url
		return nil if url.nil?

		text = url.remove("https://en.wikipedia.org/wiki/")
		return self.wiki_info text 
	end


	def self.wiki_info text
		# https://github.com/kenpratt/wikipedia-client
		require 'wikipedia'
		page = Wikipedia.find( text )
		return page
	end

	# parses the raw_data field returned from the wikipedia client
	# looks for a field 'touched' within 'pages'
	def self.parse_touched raw_data, logger = nil

        touched_string = ""

        raw_data["query"]["pages"].each_pair do |k3,v3|
          v3.each_pair do |k,v|

            if k == "touched"
              touched_string = v
              unless logger.nil?
	              logger.debug "touched: #{v}"
    		  end

            end
          end
        end

        unless logger.nil? || touched_string.strip == ""
	        logger.debug "touched: " + Time.parse(touched_string).to_s
	    end

		touched_time = (touched_string == "") ? Time.now : Time.parse(touched_string)
        return touched_time
	end
=begin
page.title

=> 'Getting Things Done'

page.fullurl

=> 'http://en.wikipedia.org/wiki/Getting_Things_Done'

page.text

=> 'Getting Things Done is a time-management method...'

page.content

=> # all the wiki markup appears here...

page.summary

=> # only the wiki summary appears here...

page.categories

=> [..., "Category:Self-help books", ...]

page.links

=> [..., "Business", "Cult following", ...]

page.extlinks

=> [..., "http://www.example.com/", ...]

page.images

=> ["File:Getting Things Done.jpg", ...]

page.image_urls

=> ["http://upload.wikimedia.org/wikipedia/en/e/e1/Getting_Things_Done.jpg"]

default width: 200

page.image_thumburls

=> ["https://upload.wikimedia.org/wikipedia/en/thumb/e/e1/Getting_Things_Done.jpg/200px-Getting_Things_Done.jpg"]

or with custom width argument:

page.image_thumburls(100)

=> ["https://upload.wikimedia.org/wikipedia/en/thumb/e/e1/Getting_Things_Done.jpg/100px-Getting_Things_Done.jpg"]

page.image_descriptionurls

=> ["http://en.wikipedia.org/wiki/File:Getting_Things_Done.jpg"]

page.main_image_url

=> "https://upload.wikimedia.org/wikipedia/en/e/e1/Getting_Things_Done.jpg"

page.coordinates

=> [48.853, 2.3498, "", "earth"]

page.templates

=> [..., "Template:About", ...]

page.langlinks

=> {..., "de"=>"Getting Things Done", "eo"=>"Igi aferojn finitaj",  "zh"=>"尽管去做", ...}

=end


end
end