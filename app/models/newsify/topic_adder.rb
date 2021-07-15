module Newsify
	class TopicAdder < ActiveRecord::Base
		self.abstract_class = true

		CLASSIFIERS = ["Google:classify","Google:entities","AWS:Comprehend","Aylien"]


	end
end