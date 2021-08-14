module Newsify
	class NewsCategories
		attr_reader :lines
		def initialize opts = {}
			parse_categories
			#add_items top_level
		end

		def self.setup!
			nc = NewsCategories.new
			nc.top_level
		end

		def top_level
			top_level_full true
			@categories.map {|k,v| k }
		end

		def top_level_full import #(import:false)
			@categories = {}
			
			@lines.each do |line|
				parts = line.split("/")

				main_name = parts[1].strip
				@categories[main_name] = {} unless @categories.has_key?(main_name)
				item = first_or_create(name:main_name,itype:"CATEGORY",is_global:true,parent_id:0) if import
				#item = Item.create({name:main_name,itype:"CATEGORY",is_global:true})
				
				#/name/sub1/sub2

				unless parts[2].nil?
					cat_name = parts[2].strip
					item2 = first_or_create(name:cat_name,parent_id:item.id,itype:"CATEGORY",is_global:true) if (import && !item.nil?)
					if parts.length == 3
						@categories[main_name][cat_name] = {} unless @categories[main_name].has_key?(cat_name)

					elsif parts.length == 4
						sub_cat_name = parts[3].strip
						item3 = first_or_create(name:sub_cat_name,parent_id:item2.id,itype:"CATEGORY",is_global:true) if (import && !item2.nil?)
						@categories[main_name][cat_name][sub_cat_name] = {} unless @categories[main_name][cat_name].nil?
					end
				end

			end
			@categories
		end

		def add_items arr
			arr.each do |name|
				Item.create(name:name,itype:"CATEGORY",is_global:true)
			end
		end

		def first_or_create(name:,parent_id:,is_global:,itype:)
			#Item.where(name: "TEST ITEM").destroy_all
		    el = Item.where(name:name,itype:"CATEGORY",is_global:true,parent_id:parent_id).first
		    if el

		    else
		      el = Item.create(name:name,itype:"CATEGORY",is_global:true,parent_id:parent_id)
		    end
		    el
		end

		# file not present in this project
		def self.json_subject_codes
			JSON.parse(File.read('import/iptc_subject_codes.json'))
		end

		def parse_categories
#			@lines = []
			#file='import/news_categories.txt'
#			file='newsify/lib/import/news_categories.txt'

#			f = File.open(file, "r")
#			f.each_line { |line|
#			  @lines.push line
#			}
#			f.close
			@lines = Newsify::GoogNewsCategories.read_to_array
		end
	end
end