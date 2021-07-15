module Newsify
	class Author < ActiveRecord::Base
		self.table_name = "authors"
		has_many :source_authors
		has_many :author_orgs

		def self.add_from_api raw_names, api_name="newsapi",org_id=nil, createdby=nil

			if raw_names.nil? || raw_names == "null"
				return []
			else

				author_ids = []
				names = raw_names.gsub(" and ","|").gsub(",","|").split("|").collect{|x| x.strip || x }
				#add authors ___ and ___, or name|name
				#if raw_names.include? " and "
				#	names = raw_names.strip.split(" and ")
				#else
				#	names = raw_names.strip.split("|")
				#end

				names.each do |name|
					author_id = Author.lookup_or_create(name,org_id,createdby)
					#lookup to see if they exist for a particular news org
					#what if it is a new news org?

					#how do we know if it is the same person just because it has the same name?
					author_ids.push author_id unless author_id.nil?
				end

				return author_ids
			end
		end

		def self.lookup_or_create name, org_id=nil,createdby=nil

			if org_id.nil?
				author = Author.where("LOWER(name) = ?",name.downcase).first
				if author.nil?
					author = Author.new(:name=>name,:createdby=>createdby)
					if author.save
						return author.id
					else
						return nil
					end
				else
					return author.id
				end

			else
				author = Author.select("authors.id")
					.joins("LEFT JOIN author_orgs ON author_orgs.author_id = authors.id")
					.where("author_orgs.org_id = ? AND LOWER(name) = ?",org_id,name.downcase).first

				#TODO: consider letting authors belong to multiple orgs
				# by...looking for an author JUST in the authors table, then adding them to author_orgs
				if author.nil?
					author = Author.new(:name=>name,:createdby=>createdby)
					if author.save
						author_org = AuthorOrg.new(:org_id=>org_id,:author_id=>author.id,:is_active=>1)
						author_org.save

						return author.id
					else
						return nil
					end
				else
					return author.id
				end
			end
		end
	end
end
