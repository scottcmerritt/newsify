class AddCachingRows < ActiveRecord::Migration[5.2]
   def change
      # we can flatten the tables (to save free rows)

      add_column :authors, :orgs_cached, :jsonb unless column_exists?(:authors, :orgs_cached)
      add_column :authors, :sources_cached, :jsonb unless column_exists?(:authors, :sources_cached)
      add_column :orgs, :authors_cached, :jsonb unless column_exists?(:orgs, :authors_cached)

      add_column :imports, :sources_cached, :jsonb unless column_exists?(:imports, :sources_cached)
   end

end
