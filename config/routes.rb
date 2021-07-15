Newsify::Engine.routes.draw do

	root controller: :news, action: :index
	
	resources :items
	resources :sources, :summaries, :authors

	match '/vote/:otype(/:oid)(/:vtype)(/:vscope)' => "votes#vote", :as => :vote, :via=> [:post, :get]
	resources :votes
  	match "/votes/audits" => "votes#audits", :as => :vote_audits, :via=>:get



	match '/profile/:id' => 'news#profile', :as => :user, :via=>[:get]

	match '/import/sources' => 'sources#import', :as => :sources_import, :via=>[:get,:post]
	match '/imported/sources' => 'sources#imported', :as => :sources_imported, :via=>[:get,:post]

	match '/auto/articles/publish' => 'news#auto_publish', :as => :auto_publish,:via=> :get

	# TODO: move these to a community ENGINE/PLUGIN
	resources :orgs
	match '/join/org/:id' => 'orgs#join', :as => :join_org,:via=> :post
	match '/leave/org/:id' => 'orgs#leave', :as => :leave_org,:via=> :post

	match '/approve/org/:id/:user_id' => 'orgs#approve_member', :as => :join_org_approve,:via=> :post
	match '/deny/org/:id/:user_id' => 'orgs#deny_member', :as => :join_org_deny,:via=> :post

	match '/remove/org_user/:id/:user_id' => 'orgs#remove_user', :as => :remove_org_user, :via => :post



end
