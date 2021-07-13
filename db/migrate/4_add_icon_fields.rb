class AddIconFields < ActiveRecord::Migration[5.2]
	def change

		
  	
  	add_column :orgs, :icon_css, :string
  	add_column :summaries, :icon_css, :string
  	

  	# add_column :users, :icon_css, :string
  	# add_column :items, :icon_css, :string
  	# add_column :rooms, :icon_css, :string
  	# add_column :room_messages, :icon_css, :string  


	end





end