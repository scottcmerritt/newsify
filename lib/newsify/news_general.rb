module Newsify
module NewsGeneral
  extend ActiveSupport::Concern

    TABS = [:browse,:auto_publish, :auto_published,:auto_unpublished,:engagement,:view_log,:summary,:article,:orgs,:articles,:info]
  
  included do
    #before_action :method_here
  
  before_action :get_ui

  before_action :summaries_overview, :only => TABS
  
  before_action :load_org, :only => [:browse,:articles]


  end


  private
    
   
  
  def load_org
    @org_id = params[:org_id].to_i
      @org = Community::Org.select("orgs.id,orgs.name as org_name,orgs.url as org_url,items.id as item_id,items.name")
      .joins("LEFT JOIN items ON orgs.item_id = items.id")
      .where("orgs.id =?",@org_id).first
  end

  def summaries_overview

    @published_count = Summary.where("NOT post_mc_guid IS NULL").count
    @published_count_recent = Summary.where("NOT post_mc_guid IS NULL AND created_at > ?",Time.now - 7.days).count

    @unpublished_count = Summary.where("post_mc_guid IS NULL").count
    @unpublished_count_recent = Summary.where("post_mc_guid IS NULL AND created_at > ?",Time.now - 7.days).count
  end
  
  def build_chart data_grouped, periods = 30, by_period = "day", logger=nil #"month","week"

    @chart_data = {:data=>[],:lbls=>[],:keys=>[]}
    data = []

    data_indexed = {}
    data_grouped.each do |drow|
      logger.debug "drow: #{drow.as_json}" unless logger.nil?
      if drow.is_a? String
        logger.debug "drow is String" unless logger.nil?
        drow = Hash[drow]
      end
      if drow.is_a?(Hash)
        logger.debug "drow is Hash" unless logger.nil?
        logger.debug "drow keys: #{drow.keys}" unless logger.nil?
        logger.debug "drow key: #{drow.keys[0]}"
        #data_indexed[drow[drow.keys[0]].to_s] = drow.values[1]
        data_indexed[drow.values[0].to_s] = drow.values[1]
        
      else
        data_indexed[drow[0].to_s] = drow[1]
      end
    end
    #data = data_indexed


    dates = []
    i = 0
    while i <= periods
      _date = by_period == "month" ? (Time.now - i.month) : (by_period == "week" ? (Time.now - i.week) : (Time.now - i.day))
      if by_period == "month"
        date_lbl = _date.strftime("%-m/%Y")
        date_key = _date.strftime("%Y-%m")
      elsif by_period == "week"
        date_lbl = _date.strftime("%W/%Y")
        date_key = _date.strftime("%Y/%W") #_date.strftime("%Y-%W")
      else
        date_lbl = _date.strftime("%-m/%-d/%Y")
        date_key = _date.strftime("%Y-%m-%d")
      end
      logger.debug "date_key: #{date_key}" unless logger.nil?
      dates.push date_key
      
      count_val = data_indexed.key?(date_key) ? data_indexed[date_key] : 0

      data_row = {}
      #data.push count_val
      
      @chart_data[:data].push count_val
      @chart_data[:keys].push date_key
      @chart_data[:lbls].push date_lbl
      
      data_row[date_key] = count_val # = {date_key => count_val}
      data.push(data_row)
      i+=1
    end

  end


  def get_ui
    @ui = {:links=>get_links}
  end
  def get_links active=nil
    #NOTE: dropdown links can't be clicked 
    # (see the btn-group demo for clickable split buttons)
    @menu_links = []
    @menu_links.push({label:"About",href:"/news",count:Room.count}) if defined?(Room)
    @menu_links.push({label:"Sources",href:newsify.sources_path,count:Newsify::Source.count,icon:"newspaper"}) #if defined?(Source) #defined?(newsify.sources_path) && defined?(Source)
    @menu_links.push({label:"Categories",href:newsify.categories_path,count:Newsify::Item.where(itype:"CATEGORY").count})
    @menu_links.push({label:"Summaries",href:newsify.summaries_path,count:Newsify::Summary.count})
    @menu_links.push({label:"Topics",href:newsify.items_path,count:Newsify::Item.count})
    

    begin
      news_blocked_sources_url.nil?
    rescue 
      #return nil
    ensure
      
    end
    

    data = []
    
    begin
    links = []

    links.push({:name=>"All",:url=>"#{browse_articles_url}",:action=>"browse"})
    links.push({:name=>"Fetched",:url=>"#{browse_articles_url(:atype=>"fetched")}",:action=>"browse"})
    links.push({:name=>"Summarized",:url=>"#{browse_articles_url(:atype=>"summarized")}",:action=>"browse"})
    links.push({:name=>"Imported",:url=>"#{browse_articles_url(:atype=>"imported")}",:action=>"browse"})
    data.push({:name=>"Articles",:url=>browse_articles_url,:action=>"browse",:links=>links})
    rescue

    end
    data.push({:name=>"Import/Publish",:url=>newsify.auto_publish_url,:action=>"auto_publish"})
    
    begin
    links = []
    links.push({:name=>"Published (this week) (#{@published_count_recent})",:url=>"#{auto_published_url}?within_hrs=#{7*24}",:action=>"auto_published"})
    links.push({:name=>"Published (all) (#{@published_count})",:url=>"#{auto_published_url}",:action=>"auto_published"})
    links.push({:divider=>true})
    links.push({:name=>"Unpublished (this week) (#{@unpublished_count_recent})",:url=>"#{auto_unpublished_url}?within_hrs=#{7*24}",:action=>"auto_unpublished"})
    links.push({:name=>"Unpublished (all) (#{@unpublished_count})",:url=>"#{auto_unpublished_url}",:action=>"auto_unpublished"})
    

    links.push({:divider=>true})
    links.push({:name=>"Extra link",:url=>"#",:action=>""})

    data.push({:name=>"Publishing",:url=>auto_published_url,:action=>"auto_published",:links=>links})
    rescue
    end

    begin
    links = []

    links.push({:name=>"Orgs (all)",:url=>"#{orgs_info_path}",:action=>"orgs"})
    links.push({:name=>"Orgs (blocking requests)",:url=>"#{news_blocked_sources_url}",:action=>"blocked_sources"})

    data.push({:name=>"News orgs",:url=>orgs_info_path,:action=>"orgs",:links=>links})
    rescue 

    end
    
    
    begin
    #data.push({:name=>"Unpublished (#{@unpublished_count_recent})",:url=>"#{auto_unpublished_url}",:action=>"auto_unpublished",:links=>links})

    data.push({:name=>"Time spent",:url=>"#{news_view_log_url}",:action=>"view_log"})
    data.push({:name=>"Engagement",:url=>"#{news_engagement_url}",:action=>"engagement"})
    data.push({:name=>"Admin",:disabled=>true,:url=>"#{admin_index_url}",:action=>"admin"})

  rescue

  end
    logger.debug params[:action]
    data.each_with_index do |d,i|
      if active.nil? && d[:action] == params[:action]
        active = i
      end
    end
    output = {:data=>data,:active=>active}
    return output
  end

end
end