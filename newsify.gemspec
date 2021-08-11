require_relative "lib/newsify/version"

Gem::Specification.new do |spec|
  spec.name        = "newsify"
  spec.version     = Newsify::VERSION
  spec.authors     = ["MC Dev"]
  spec.email       = ["dev@meritocracyconsulting.com"]
  #spec.homepage    = "TODO"
  spec.summary     = "Read the news. Share the news. Discus the news."
  spec.description = "Adds news functionality to apps."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  #spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.1.4"
  spec.add_dependency "kaminari"
  spec.add_dependency "acts_as_votable"
  spec.add_dependency "acts_as_favoritor"
  spec.add_dependency "tactful_tokenizer"
  spec.add_dependency "narray"
  spec.add_dependency "tf-idf-similarity"

  spec.add_dependency "aylien_text_api"
  spec.add_dependency "google-cloud-language"

  spec.add_dependency "diffy"
  spec.add_dependency "custom_sort"
  spec.add_dependency "sortify" #, :git => 'git://github.com/scottcmerritt/sortify.git', :branch=> "main"
  spec.add_dependency "wikipedia"
  spec.add_dependency "wikipedia-client"
end
