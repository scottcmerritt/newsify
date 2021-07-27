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

    def label_w_count lbl, count, with_delim=","
      raw("#{lbl} #{tag.span num_format(count,0,with_delim), class:"badge badge-info"}")
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

    def default_badge_css size: 'md', tight: false, active: false, color: 'info', active_color: 'dark'
      "badge #{active ? "badge-#{active_color}" : "badge-#{color} bg-#{color}"} border rounded #{tight ? 'mr-1' : 'mx-1'} #{size == 'sm' ? 'px-1' : 'p-2'}"
    end

    def my_paginate data, page: 12
      page = page.nil? ? 1 : page.to_i
      prev_page = newsify.items_path(page:page-1)
      next_page = newsify.items_path(page:page+1)
      render(partial:"newsify/util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}})
    end

  end
end
