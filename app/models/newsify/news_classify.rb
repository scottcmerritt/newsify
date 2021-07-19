module Newsify
  # shared functionality for classifying news related models
  module NewsClassify
    # NOTE: this next line was commented out, not sure if that was intentional
    extend ActiveSupport::Concern

    def import_keywords
      Import.select("keyword")
      .joins("LEFT JOIN import_sources ON imports.id = import_sources.import_id")
      .where("import_sources.source_id = ?",self.id)
    end

    def source_groups
      SourceGroup.where(source_id: self.id)
    end

    # alias for similar_sources
    def similar
      similar_sources
    end
    def similar_sources
      if self.is_a? Source
        if self.is_group == true
          return Source.select("sources.*")
          .joins("LEFT JOIN source_groups ON source_groups.child_id = sources.id")
          .where("source_groups.source_id = ?",self.id).where.not("sources.id": self.id)
        else
          #source_group_ids = self.group_id.nil? ? self.source_groups.pluck(:id) : self.group_id
        
          #TODO: do we need to add the source_groups.source_id (in addition to the child_id?)
          unless self.group_id.nil?
          sources = Source.select("sources.*")
          .joins("LEFT JOIN source_groups ON source_groups.child_id = sources.id")
          .where("sources.id = ? OR (NOT sources.id = ? AND source_groups.source_id = ?)", self.group_id,self.id,self.group_id)
          


          #sources = sources.where("source_groups.id": source_group_ids) unless self.group_id.nil?
          return sources
          end

        end
      end

    end
  end
end