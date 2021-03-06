Newsify::Engine.routes.draw do

	root controller: :news, action: :index
	
	resources :items
	resources :sources, :summaries, :authors, :summary_sources

	resources :stats

	match 'admin' => 'news#admin', :as=> :newsify_admin, :via=>:get
	match 'search' => 'news#search', :as=> :newsify_search, :via=>:get
	match 'activity' => 'news#activity', :as=> :newsify_activity, :via=>:get

	match '/browse/:otype(/:oid)' => "items#browse", :as => :browse_otype, :via=> :get

	

	match 'admin/calc/fame' => 'news#calc_fame', :as=> :newsify_calc_fame, :via=>:get
	match 'admin/calc/interests' => 'news#calc_interests', :as=> :newsify_calc_interests, :via=>:get

	match '/profile(/:id)/interests/edit' => 'interests#interests_edit', :as => :profile_interests_edit, :via => :get, order: "desc"
  	match '/profile(/:id)/interests' => 'interests#interests', :as => :profile_interests, :via => :get, order: "desc"
  	match '/profile(/:id)/disinterests' => 'interests#interests', :as => :profile_disinterests, :via => :get
  	
  	#match "/start/scroll/feed" => "feed#scroll", :as => :feed_scroll, :via=>[:get,:post]
  	match "/start/report/feed" => "feed#report", :as => :feed_report, :via=>:get
  	match "/start/feed" => "feed#start", :as => :feed_start, :via=>:get

  	match "/feed" => "feed#scroll", :as => :feed, :via=>:get # was feeds#mine
  	match "/feed/(:label)" => "feed#labeled", :as => :feed_labeled, :via=>:get


	# next 3 routes not implemented/used
	match "/recent/feed/(:label)" => "feed#recent", :as => :feed_recent, :via=>:get
	match "/recent/voted/feed/(:label)" => "feed#recent_voted", :as => :feed_recent_voted, :via=>:get
	match "/recent/ignored/feed/(:label)" => "feed#recent_ignored", :as => :feed_recent_ignored, :via=>:get


	match "/sources/:id/opinions" => "sources#opinions", :as=>:source_opinions_all, :via=>:get


	match '/vote/:otype(/:oid)(/:vtype)(/:vscope)' => "votes#vote", :as => :vote, :via=> [:post, :get]
	resources :votes
  	match "/votes/audits" => "votes#audits", :as => :vote_audits, :via=>:get
  	match "/feedback" => "votes#index", :as => :feedback, :via=>:get

  	match '/interested(/:otype)(/:view)' => 'rank#interested', :as => :otype_interested, :via => :get

	match '/profile/:id' => 'news#profile', :as => :user, :via=>[:get]

	match '/grouped/sources' => 'sources#grouped', :as => :sources_grouped, :via=>[:get,:post]
	match '/similar/sources' => 'sources#similar', :as => :sources_similar, :via=>[:get,:post]
	

	match '/import/start' => 'news#import_start', :as => :news_import, :via=>[:get,:post]

	match '/import/sources' => 'sources#import', :as => :sources_import, :via=>[:get,:post]
	match '/imported/sources' => 'sources#imported', :as => :sources_imported, :via=>[:get,:post]
	match '/import/sources/classify/:import_id' => 'sources#import_classify', :as => :sources_import_classify, :via=>[:get,:post]

	match '/auto/articles/publish' => 'news#auto_publish', :as => :auto_publish,:via=> :get

	# TODO: move these to a community ENGINE/PLUGIN

	match '/filtered/orgs/:org_type(/:filter)' => 'orgs#index', :as => :orgs_by_type,:via=> :get

	resources :orgs
	match "/group/:id" => "orgs#show", :as => :group, :via=>:get
	match '/join/org/:id' => 'orgs#join', :as => :join_org,:via=> :post
	match '/leave/org/:id' => 'orgs#leave', :as => :leave_org,:via=> :post

	match '/approve/org/:id/:user_id' => 'orgs#approve_member', :as => :join_org_approve,:via=> :post
	match '/deny/org/:id/:user_id' => 'orgs#deny_member', :as => :join_org_deny,:via=> :post

	match '/remove/org_user/:id/:user_id' => 'orgs#remove_user', :as => :remove_org_user, :via => :post




	# Items
	match '/import/categories' => 'items#import_categories', :as => :categories_import, :via=>[:get,:post]
	#match '/categories' => 'items#categories', :as => :categories, :via=>[:get,:post]
	match "/categories(/:page)" => "items#index", :as=>:categories, :via=>:get, itype: "CATEGORY", join: false, parent_id: 0
	match "/types/items/:itype" => "items#itype", :as=> :item_itype, :via=>:get
  	match '/labeled/items(/:label)' => 'items#labeled', :as=>:items_labeled, :via=>:get

  	# extra labeled stuff
  	match '/labeled/sources(/:label)' => 'sources#labeled', :as=>:sources_labeled, :via=>:get
  	match '/labeled/summaries(/:label)' => 'summaries#labeled', :as=>:summaries_labeled, :via=>:get
  	match "/items/:id/import" => "items#import", :as=> :item_import, :via=>:get


	#TODO: better organize these admin routes
	match '/admin/classify' => 'classify#index', :as=>:admin_classify,:via=>[:get,:post]
	match '/admin/classify/v2' => 'admin#classify_full', :as=>:admin_classify_v2, :via=> :get


	match '/admin/guess/upvotes/news' => 'classify#guess_upvotes_news', :as=>:admin_guess_upvotes_news, :via=>[:post,:get]
	match '/admin/classify/disambiguate' => 'classify#disambiguate', :as=>:admin_classify_disambiguate,:via=>[:post,:get]
	match '/admin/classify/disambiguate/preview' => 'classify#disambiguate_preview', :as=>:admin_classify_disambiguate_preview,:via=>[:get,:post]
	match '/similarity/news' => 'classify#news_similar', :as=>:admin_news_similar, :via=>[:post,:get]


	match "/connections" => "connect#list", :as => :connections, :via=>:get
	match "/add/connection/:otype/:id" => "connect#add", :as => :add_connection, :via=>:get
  	match "/cancel/connection/:otype/:id" => "connect#cancel", :as => :cancel_connection, :via=>:get

end
