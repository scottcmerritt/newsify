module Newsify
  module CachedOrgs
    extend ActiveSupport::Concern

    # this is a method thats called when you include the module in a class.
    def self.included(base)
      base.extend ClassMethods
    end

     module ClassMethods
      def cache_authors! archive:false, limit:10, offset: 0
        data = limit.nil? ? Community::Org.all : Community::Org.limit(limit).offset(offset)
        data.each do |org|
          org.cache_authors! archive: archive
        end
      end
    end

    def cache_authors! archive:false, undo: false
      if undo
        self.authors_cached['active'].each do |author_id|
          self.author_orgs.create(author_id: author_id,org_id:self.id,is_active:true)
        end
        self.authors_cached['inactive'].each do |author_id|
          self.author_orgs.create(author_id: author_id,org_id:self.id,is_active:false)
        end
      else
        self.author_orgs.each do |author_org|
          author_org.author.cache_orgs!(archive: archive)
        end
      end
    end


    # add active and inactive author ids
    def cache_author! active_id: nil, inactive_id: nil
      if self.authors_cached.nil? || self.authors_cached['active'].nil?
        self.authors_cached = {'active':[],'inactive':[]}
        self.save
        self.reload
      end

      cached_rows = self.authors_cached
      cached_rows['active'].push(active_id) if !active_id.nil? && !cached_rows['active'].include?(active_id)
      cached_rows['inactive'].push(inactive_id) if !inactive_id.nil? && !cached_rows['inactive'].include?(inactive_id)
      self.authors_cached = cached_rows
      self.save
    end
    def cache_info
      return nil if self.authors_cached.nil?
      return nil if self.authors_cached['active'].nil?
      "#{self.authors_cached['active'].length} active, #{self.authors_cached['inactive'].length} inactive"  
    end

    def authors both:false
=begin
      return Author.select("authors.*")
      .joins("LEFT JOIN author_orgs ON author_orgs.author_id = authors.id")
      .where("org_id = ?",self.id)
=end
      active_ids = author_orgs.where(is_active:true).pluck(:author_id) + (self.authors_cached.nil? ? [] : (self.authors_cached.dig('active') || []))
      Rails.logger.debug "active_ids: #{active_ids}"
      active_authors = Newsify::Author.where(id:active_ids)
      return active_authors if !both
      inactive_ids = author_orgs.where(is_active:false).pluck(:author_id) + (self.authors_cached.nil? ? [] : (self.authors_cached.dig('inactive') || []))
      Rails.logger.debug "inactive_ids: #{inactive_ids}"
      {active: active_authors,inactive:Newsify::Author.where(id:inactive_ids)}
    end
    def authors_count
      self.authors(both:true)[:active].length + self.authors(both:true)[:inactive].length
    end

  end
end
