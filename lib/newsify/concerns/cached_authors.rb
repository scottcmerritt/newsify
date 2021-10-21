module Newsify
  module CachedAuthors
    extend ActiveSupport::Concern

    def orgs both:false

      # merge author_orgs with authors.orgs_cached
      
      active_ids = author_orgs.where(is_active:true).pluck(:org_id) + (self.orgs_cached['active'].nil? ? [] : self.orgs_cached['active'])
      active_orgs = Community::Org.where(id:active_ids)
      return active_orgs if !both
      inactive_ids = author_orgs.where(is_active:false).pluck(:org_id) + (self.orgs_cached['inactive'] || [])
      {active: active_orgs,inactive:Community::Org.where(id:inactive_ids)}
    end
    
    def cache_info
      return nil if self.orgs_cached.nil?
      return nil if self.orgs_cached['active'].nil?
      "#{self.orgs_cached['active'].length} active, #{self.orgs_cached['inactive'].length} inactive"  
    end

    def cache_orgs!(archive:false)
      if self.orgs_cached.nil? || self.orgs_cached['active'].nil? || self.orgs_cached['active'].kind_of?(String)
        self.orgs_cached = {'active':[],'inactive':[]}
        self.save
        self.reload #orgs_cached.reload
      end
      cached_rows = self.orgs_cached #.nil? || self.orgs_cached['active'].nil? ? {'active':[],'inactive':[]} : self.orgs_cached

      self.author_orgs.each do |row|
        row.org.cache_author!(active_id: row.author_id) if row.is_active == true
        row.org.cache_author!(inactive_id: row.author_id) if row.is_active != true

        addkey = row.is_active == true ? 'active' : 'inactive'
        removekey = row.is_active == true ? 'inactive' : 'active'
        Rails.logger.debug "CACHED ROWS"
        Rails.logger.debug cached_rows
        Rails.logger.debug row.org_id
        Rails.logger.debug addkey
        if [3].include?(3)
          Rails.logger.debug "arr has val"
        end

        Rails.logger.debug "SHOULD BE empty arr: #{cached_rows[addkey]}"
        Rails.logger.debug cached_rows[addkey].length

        if cached_rows[addkey].include?(row.org_id)
          Rails.logger.debug "including"
        else
          Rails.logger.debug "not including"
        end
        cached_rows[addkey].push(row.org_id) unless cached_rows[addkey].include?(row.org_id)
        cached_rows[removekey] = cached_rows[removekey] - [row.org_id] if cached_rows[removekey].include?(row.org_id) # .delete(row.org_id) 
      end
      self.orgs_cached = cached_rows
      if self.save
        if archive == true

          self.author_orgs.destroy_all        
        end
      end
      

    end

  end

end
