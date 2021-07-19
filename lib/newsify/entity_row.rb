module Newsify
  class EntityRow
    attr_reader :name, :type, :salience, :wiki_url
    def initialize options = {}
      @name = options[:name]
      @type = options[:type]
      @salience = options[:salience]
      @wiki_url = options[:wiki_url]
    end
  end
end