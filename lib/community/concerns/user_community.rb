module Community
  module UserCommunity
    extend ActiveSupport::Concern

=begin
  # currently in Feedbacker::UserInfo
    scope :spam, -> { where("(removed = ? AND is_spam = ?)",false,true) }
    scope :not_spam, -> { where("(removed = ? AND (is_spam is null OR is_spam = ?) )",false,false) }
    scope :confirmed, -> { where("(NOT confirmed_at is null)")}
    scope :not_confirmed, -> { where("(confirmed_at is null)")}
=end    

    def interests_total
      Newsify::ItemInterest.where(user_id: self.id).count
    end

    def my_groups viewed_by = nil, limit = 10
    groups = Community::Org.select("orgs.id,orgs.name,orgs.icon_css,COUNT(org_users.id),is_debate")
    .joins(:org_users) #:org_users
    .joins("LEFT JOIN org_users ou2 ON ou2.org_id = orgs.id")
    .group("orgs.id,orgs.name,is_debate")
    .where('ou2.user_id = ? AND ou2.is_pending = ? AND ou2.removed = ? AND org_users.removed = ? AND org_users.is_pending = ?',self.id,false,false,false,false)
    .where.not("orgs.is_debate = ?",true)
    .order('COUNT(org_users.id) DESC')
   end


    def display_name_public
      email
    end
=begin
    def display_name_default
      "User #{self.id}"
    end
    def display_name_public
      res = self.settings(:prefs).is_public ? self.settings(:profile).full_name : display_name_default
      res.blank? ? display_name_default : res
    end
=end


    def post_count
      Newsify::Source.where(createdby: self.id).count + (defined?(Post) ? Post.where(user_id:self.id).count : 0)
    end


    def connect! user
      self.friend_request(user)
      user.accept_request(self)
    end

    # NOTE: requires the Feedbacker::UserInfo is included BEFORE (to use online_via_impression?)
    def online?
      return self.online_via_impression? if !defined?(Newsify::Cache) && self.respond_to?(:online_via_impression?)
      return nil if !defined?(Newsify::Cache)
      online_key = "online::#{self.id}"
      #Cache.exists? online_key
      Newsify::Cache.time_to_live(online_key) > 0 
    end




    #def online?
    #  Impression.where("user_id = ? AND created_at > ?",self.id,10.minutes.ago).exists?
    #end

=begin  
    # currently in Feedbacker::UserInfo

    def total_views
      Impression.where("user_id = ?",self.id).count
    end
    def last_view
      Impression.where("user_id = ?",self.id).order("created_at DESC").first.created_at unless Impression.where("user_id = ?",self.id).order("created_at DESC").first.nil?
    end
   

    def last_activity
      [self.last_view,self.current_sign_in_at,self.last_sign_in_at,self.created_at,self.updated_at].compact.max
  #    (!user.current_sign_in_at.nil? && (user.current_sign_in_at > minutes_ago.minutes.ago)) || (!user.last_sign_in_at.nil? && (user.last_sign_in_at > minutes_ago.minutes.ago) )

    end
    
   
    def self.order_by_ids(ids)
      t = User.arel_table
      condition = Arel::Nodes::Case.new(t[:id])
      ids.each_with_index do |id, index|
        condition.when(id).then(index)
      end
      order(condition)
    end

    def self.active_users minutes_ago: 60
      user_list = User.not_spam.each.collect{|user| user if user.online? || (user.last_activity > minutes_ago.minutes.ago) }.compact.sort_by{|user| user.last_activity}.reverse
      ids = user_list.pluck(:id)
      User.where(id: ids).order_by_ids(ids)
    end
=end    



    
    def online! room_id: nil
      unless room_id.nil?
        room_user_key = "room_user::#{room_id}::#{self.id}"
          Newsify::Cache.add_list_item "room_users::#{room_id}", room_user_key
        if Newsify::Cache.exists? room_user_key
          Newsify::Cache.change_expiration! room_user_key, 60
        else
          Newsify::Cache.set_obj room_user_key, self.id, nil, 60
        end
      else

        online_key = "online::#{self.id}"
        Newsify::Cache.add_list_item "online_users", online_key
        if Newsify::Cache.exists? online_key
          Newsify::Cache.change_expiration! online_key, 240
        else
          Newsify::Cache.set_obj online_key, self.id, nil, 240
        end
      
      end
    end   

  end
end