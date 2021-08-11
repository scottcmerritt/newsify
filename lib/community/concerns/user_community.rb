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
 

end
end