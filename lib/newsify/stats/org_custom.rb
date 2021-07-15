class OrgCustom


	def self.test_sql
		"(select
       orgs.id,
       orgs.name,
       1 as vote_count
       from orgs ) as orgs"
	end

	def self.top_orgs_sql vote_scope = "interesting", minimum_votes = 2

		"(select
       orgs.id,
       orgs.name,
       SUM(vote_count) as vote_count
       from orgs
       join (
       	select
	       	id as source_id,
       		org_id
       		from sources
       ) sources ON org_id = orgs.id
       join (
	       select votable_id as source_id,
	       COUNT(votes.id) as vote_count
	       from votes
	       where voter_type = 'User' AND votable_type = 'Source' AND vote_scope = '#{vote_scope}'
	       group by votable_id
       ) votes_info using(source_id) 
       ) as orgs
       where vote_count > #{minimum_votes}
       group by id, orgs.name
       "

	end

	def self.top_orgs limit = 20
		fields = ["cached_content_score"]
		Community::Org.select("orgs.*, #{fields.join(',')}").joins("LEFT JOIN vote_caches ON orgs.id = vote_caches.resource_id")
		.where("resource_type = ?","Community::Org")
		.order("cached_content_score DESC")
		.limit(limit)

	end
	def self.top_orgs_new limit = 20
		Community::Org.select("orgs.id,orgs.name,SUM(vote_caches.cached_votes_total) as vote_count")
		.joins("LEFT JOIN sources ON sources.org_id = orgs.id")
		.joins("LEFT JOIN vote_caches ON orgs.id = vote_caches.resource_id")
		.where("resource_type = ?","Source")
		.order("vote_count DESC")
		.group("orgs.id,orgs.name")
		.limit(limit)
	end

	def self.top_orgs_sql_cached vote_scope = "interesting", minimum_votes = 2

		col = "cached_weighted_#{vote_scope}_score"

		"(select
       orgs.id,
       orgs.name,
       SUM(vote_count) as vote_count
       from orgs
       join (
       	select
	       	id as source_id,
       		org_id
       		from sources
       ) sources ON org_id = orgs.id
       join (
	       select resource_id as source_id,
	       SUM(#{col}) as vote_count
	       from vote_caches
	       where resource_type = 'Source'
	       group by resource_id
       ) votes_info using(source_id) 
       ) as orgs
       where vote_count > #{minimum_votes}
       group by id, orgs.name
       "

	end

	 def self.top_voted(count=1)
    sql = OrgCustom.top_orgs_sql_cached
    Community::Org.from(sql)
      .order(vote_count: :desc)
      .limit(count)
  end

end