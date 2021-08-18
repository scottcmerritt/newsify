module Community
  module UserCommunity
    extend ActiveSupport::Concern

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


    def post_count
      Newsify::Source.where(createdby: self.id).count + (defined?(Post) ? Post.where(user_id:self.id).count : 0)
    end


    def connect! user
      self.friend_request(user)
      user.accept_request(self)
    end


    def online?
      return nil if !defined? Newsify::Cache
      online_key = "online::#{self.id}"
      #Cache.exists? online_key
      Newsify::Cache.time_to_live(online_key) > 0 
    end

    
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