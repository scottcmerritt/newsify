module Community
module UserUtility
  # used by controllers
  extend ActiveSupport::Concern
    
  def view_news_prefs?
    @user.id == current_user.id || is_admin?
  end

end
end