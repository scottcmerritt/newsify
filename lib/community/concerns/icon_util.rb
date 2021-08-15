module Community
module IconUtil

  def has_icon_class?

  end

  def has_icon_class?
    return (self.respond_to?(:icon_css) || self.respond_to?(:icon_class))
  end

  def self.oicon 
    _prefix = "fa fa-fw fa-"

    nil #if self.is_a? User
  end

  def icon_guessed
    if defined?(Room) && self.is_a?(Room)
      default_icon = "fa fa-comments"
      return self.icon_css.blank? ? (self.item.nil? ? default_icon : self.item.icon_guessed) : self.icon_css
    elsif self.is_a? Community::VoteAudit
      return "fa fa-check-circle"
    else
      return (!self.respond_to?(:icon_css) || self.icon_css.blank?) ? self.get_icon_class : self.icon_css #(self.item.nil? ? self.icon_css : self.item.icon_css) : self.icon_css
    end

  end

  def oicon
    #TODO: accomodate multiple main icons, plus sub-icons (for private,public,scheduled, archived, etc...)
    # make sure to highlight posts.sender_del

    if self.has_icon_class?
      self.icon_class
    else
      self.get_icon_class
    end
  end

  def icon_map
    # by_name = 
    {"posts"=>"comment"}
    #by_class = {}

  end

  def lookup_icon_class icon_target_name, library = "fontawesome"
    self.get_icon_class({:name=>icon_target_name,:library=>library})
  end

  # gets the icon css
  def get_icon_class opts = {:library=>"fontawesome"}
     _prefix = opts[:library] == "fontawesome" ? "fa fa-fw fa-" : ""
    if opts[:name]
      _lookup = opts[:name].pluralize(2)
      if self.icon_map.has_key?(_lookup)
        return _prefix + self.icon_map[_lookup]
      else
        return _prefix + "asterisk"
      end
    else

      if self.is_a? User
        _prefix + "user"
      elsif self.is_a? Newsify::Item
        case self.itype
        when "PERSON" 
          _prefix+"user"
        when "TOPIC"
          _prefix+"sitemap"
        when "SOUND"
          _prefix+"music"
        when "FITNESS"
          _prefix+"music"
        else
          _prefix+"sitemap"
        end

      elsif defined?(Room) && self.is_a?(Room)
        _prefix + "comments"
      elsif self.is_a? Community::Org
        _prefix + "users"
      elsif defined?(RoomMessage) && self.is_a?(RoomMessage)
        _prefix + "comment"
      elsif self.is_a? Newsify::Summary
        _prefix + "newspaper"
      elsif self.is_a? Newsify::Source
        _prefix + "newspaper"
      elsif self.is_a? Describe
        _prefix + "sticky-note"
      elsif self.is_a? Idea
        # is_vote, archived
        if self.archived 
          _prefix+"history"
        elsif !self.seriesid.nil? && self.seriesid > 0
          #this is likely an agenda item or a part of a story
          nil
        elsif !self.startdate.nil?
          _prefix+"calendar-day"
        elsif self.is_story
          _prefix+"book-reader"
        elsif self.is_likely_template?  #TODO: fix this VERY sloppy and unecessary code
          _prefix+"asterisk"
        else
          _prefix+"lightbulb"
        end
      elsif self.is_a? Thing
        _prefix+"icons"
     
      elsif self.is_a? Post
        if self.is_task?
          _prefix+"tasks"
        elsif self.is_msg
          _prefix+"comment"
        elsif self.is_post
           _prefix+"newspaper"
        else
          _prefix+"question"
        end
      else 
        _prefix+"asterisk" #nil 
        # or "info-circle", "info" "bell" 
        # "calendar-check" "calendar-times" "calendar-plus" "calendar-day", "calendar-week" "table" "database" "clock"
        # "question" "question-circle"
        # STORY: "book-open", "book-reader", "book", "newspaper"
        # MUSIC "headphones"
      end
    end


  end

end
end