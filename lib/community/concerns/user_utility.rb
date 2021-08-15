module Community
module UserUtility
  # used by controllers
  extend ActiveSupport::Concern
    
  def view_news_prefs?
    @user.id == current_user.id || is_admin?
  end

  def get_voter_type 
    current_user.class.name
  end
  def get_votable_type 
    current_user.class.name
  end

end
end