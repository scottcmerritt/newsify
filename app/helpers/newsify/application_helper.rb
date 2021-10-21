module Newsify
  module ApplicationHelper
      def past_tense_event event
        case event
        when "update"
          "updated"
        when "create"
          "added"
        when "destroy"
          "removed"
        else
          event
        end
      end
      
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


    #TODO: add condensed mode for OTHER languages
    def date_fmt date, fmt: nil, verbose: false

      lang = I18n.locale.to_s

      lookup = {
        "en" => {:about => "about",:less => "less than a", :durations => ["day","minute","hour","year"]},
        "es" => {:about => "alrededor de",:less => "menos de", :durations =>["día","minuto","hora","año"]}
        }

      logger.debug "LOCALE::: #{I18n.locale.to_s}"
      if !(I18n.locale.to_s == "en")
        logger.debug "LOCALE1::: HIT"
      else
        logger.debug "LOCALE1::: MISS"
      end
      #verbose = true if !(I18n.locale.to_s == "en")

      if fmt == "ago"
        res = time_ago_in_words date #date.strftime("%-m/%-d/%y") +  " at " + date.strftime("%l:%M%P")
        
        unless verbose

          lookup[lang][:durations].each do |duration|
            res = res.sub(duration+"s",duration[0]).sub(duration,duration[0])
          end
          res = res.sub(lookup[lang][:about],"~")
          res = res.sub(lookup[lang][:less], lang == "en" ? "~1" : "~")
          res = res.delete(" ")
        end
        # .gsub(/\s+/, "") # removes ALL white space

      else
        res = date.strftime("%-m/%-d/%y") +  " at " + date.strftime("%l:%M%P")
      end


      res
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

    def nav_item lbl, href, count, is_active = false, css = "", icon:nil
      custom_css = "nav-item py-1 border d-flex #{ is_active ? "bg-light text-dark" : "bg-dark text-light"}"
      #tag.li link_to(label_w_count(lbl,count), href, class: "nav-link#{" active" if is_active} #{css}"), class: custom_css
      tag.li link_to(icon.nil? ? lbl : icon(lbl:lbl,icon:icon), href, class: "nav-link#{" active" if is_active} #{css}"), class: custom_css
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

    # bg-secondary.bg-gradient
    def default_badge_css size: 'md', tight: false, active: false, color: 'secondary', active_color: 'dark', text_color: 'light', text_color_active: 'light'
      "badge #{active ? "badge-#{active_color} bg-#{active_color} text-#{text_color_active}" : "badge-#{color} bg-#{color} text-#{text_color}"} bg-gradient border rounded #{tight ? 'mr-1' : 'mx-1'} #{size == 'sm' ? 'px-1' : 'p-2'}"
    end

    # used for moderation
    def default_badge_css2 size: 'md', tight: false, active: false, color: 'info', active_color: 'dark'
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
    def newsify_widget_sources show: nil, data: nil
      data = Newsify::Source.order("created_at DESC").limit(5) if data.nil? 
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
