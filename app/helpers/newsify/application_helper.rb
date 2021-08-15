module Newsify
  module ApplicationHelper
    def num_comma num, decimal_places = 0, with_delim = ","
      num_format num, decimal_places, with_delim
    end
    def num_format num, decimal_places=2,with_delim=nil
      if with_delim.nil?
        num = number_with_precision(num, :precision => decimal_places)
      else
        num = number_with_precision(num, :precision => decimal_places,:delimiter=>",")
      end
      return num
    end


    def date_fmt date, fmt: nil, verbose: false
      if fmt == "ago"
        res = time_ago_in_words date #date.strftime("%-m/%-d/%y") +  " at " + date.strftime("%l:%M%P")
        unless verbose
          ["day","minute","hour","year"].each do |duration|
            res = res.sub(duration+"s",duration[0]).sub(duration,duration[0])
          end
          res.sub("about","~").delete(" ")
        end
        # .gsub(/\s+/, "") # removes ALL white space
      else
        date.strftime("%-m/%-d/%y") +  " at " + date.strftime("%l:%M%P")
      end
    end
=begin
    def created_at_date
      self.created_at.strftime("%-m/%-d/%y")
    end
    def created_at_time
      self.created_at.strftime("%l:%M%P")
    end
=end

    def label_w_count lbl, count, with_delim=","
      raw("#{lbl} #{tag.span num_format(count,0,with_delim), class:"badge bg-info badge-info"}")
    end

    def nav_link lbl, href, count, is_active = false, css = ""
      link_to label_w_count(lbl,count), href, class: "nav-link#{" active" if is_active} #{css}"
    end


    def otype_labeled_href otype, label
      if ["source","sources"].include? otype
        newsify.sources_labeled_path(label: label)
      elsif ["summary","summaries"].include? otype
        newsify.summaries_labeled_path(label: label)
      elsif ["feed","feeds"].include? otype
        newsify.feed_labeled_path(label: label)
      else
        newsify.items_labeled_path(label: label)
      end
    end

    def guess_otype obj
      obj.class.name.split("Newsify::")[-1]
    end

    def default_badge_css size: 'md', tight: false, active: false, color: 'info', active_color: 'dark'
      "badge #{active ? "badge-#{active_color}" : "badge-#{color} bg-#{color}"} border rounded #{tight ? 'mr-1' : 'mx-1'} #{size == 'sm' ? 'px-1' : 'p-2'}"
    end

    def my_paginate data, page: 1, categories: false, label: nil
      page = [1,"1",nil].include?(page) ? 1 : page.to_i
      if label
        if data.klass == Newsify::Source
          prev_page = newsify.sources_labeled_path(request.parameters.except(:controller, :action, :id).merge({page:@page-1}))
          next_page = newsify.sources_labeled_path(request.parameters.except(:controller, :action, :id).merge({page:@page+1}))
        else
          prev_page = newsify.items_labeled_path(page:page-1,label:label)
          next_page = newsify.items_labeled_path(page:page+1,label:label)
        end
      else
        if data.klass == Newsify::Summary
          prev_page = categories ? newsify.categories_path(page:page-1) : newsify.summaries_path(page:page-1)
          next_page = categories ? newsify.categories_path(page:page+1) : newsify.summaries_path(page:page+1)
        elsif data.klass == Newsify::Source
          prev_page = newsify.sources_path(request.parameters.except(:controller, :action, :id).merge({page:@page-1})) 
          next_page = newsify.sources_path(request.parameters.except(:controller, :action, :id).merge({page:@page+1}))
        else
          prev_page = categories ? newsify.categories_path(page:page-1) : newsify.items_path(page:page-1)
          next_page = categories ? newsify.categories_path(page:page+1) : newsify.items_path(page:page+1)
        end

      end
      render(partial:"newsify/util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}})
    end

    def org_paths
      org_type = params[:org_type] if params[:org_type]
      if org_type
        return {:prev=>newsify.orgs_by_type_path(org_type: org_type,page:@page-1),:next=>newsify.orgs_by_type_path(org_type: org_type,page:@page+1)}
      else
        return {:prev=>newsify.orgs_path(page:@page-1),:next=>newsify.orgs_path(page:@page+1)}
      end
    end


    def newsify_draw_orgs
      #render(partial:"shared/hello", locals: {target: target, path_to_resource:path_prepped, data:data}) # + render(partial:"shared/hello2")
      render(partial:"newsify/orgs/index")
    end

    # widget on home page
    def newsify_widget_sources show: nil
      data = Newsify::Source.order("created_at DESC").limit(5)
      render(partial:"newsify/sources/widgets/index", locals: {data:data,show:show})

    end

    # used for generating a power meter underneath a div
    def lbl_meter text,score:, meter_height:"2px"
      wd = Math.tan(score)*100.0 +0.15
      wd = wd > 100 ? 100 : wd
      meter_color = "green"
      tag.div(tag.div(text)+tag.div("",style:"width:#{wd}%;height:#{meter_height};background-color:#{meter_color}"))
    end

=begin
    def news_paginate resources, params: nil
      paginate resources, params: params #{controller: "newsify/summaries", action: "index", page: 1}
    end
=end
  end
end
