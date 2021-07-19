module Newsify
	module TextUtil
	  extend ActiveSupport::Concern
	  
		def get_sentences text= nil
			
			text = self.guess_text_to_parse if text.nil?
			
			#require "tactful_tokenizer"
			m = TactfulTokenizer::Model.new
			return m.tokenize_text(text)

			return text.split("\n")
		end

		def get_words text = nil
			text = self.guess_text_to_parse if text.nil?
			text.scan(/\w+/)
		end

		def guess_text_to_parse
			text = ""
			if self.is_a? Content
				text = self.article
				sentences = self.article.split("\n")
			else
				text = []
				text.push(self.title) if self.respond_to?(:title)
				text.push(self.details) if self.respond_to?(:details)
				text.push(self.description) if self.respond_to?(:description)
				text = text.join(" ")
			end
			return text
		end

		def word_count text = nil
			if text.nil?
				text = self.guess_text_to_parse
			end
			text.scan(/\w+/).size # + self.article.scan(/\w+/).size
		end

		def auto_html_format
			
			# this works
			#paragraph_count = self.article.split("\.\r").length
			
			return self.get_sentences.join("\n\n")

			return "TEST " + self.get_sentences.join("\n").split(". ").join(". \n\n")

			text = self.article.split(".").join(" ")

			#return self.article.split("\n").size

			sentences = self.article.split("\n")
			sections = sentences.map do |sentence|
				"<div>"+sentence+"</div>"
			end
			return sections
			# this gets an array of words in order, with characters removes
			#paragraphs = text.split(/\s*?\r\s*/).map do |paragraph|
			#  paragraph.scan(/[[:alnum:]]+/).uniq
			#end

			#return paragraphs.to_s

			sentences = self.article.split("/\w/\n")
			return sentences

			divs = sentences.map{|sentence| "<div class='border p-1 m-1'>#{sentence}</div>"}
			return divs.join
			#return sentences.join("</br>")
		end

	end


end