module Newsify
  class SourcesController < ApplicationController
    before_action :setup_pager

    def index
      
      Newsify::Cache.set_obj "my_test_key", "hello"
      @cache_result = Newsify::Cache.get_obj "my_test_key"

      @labeled = Source.order("created_at DESC")
      .page(@page).per(20)
    end
    def show
      @source = Source.find_by(id:params[:id])
    end
    def imported

      @labeled = Source.joins("LEFT JOIN import_sources ON sources.id = import_sources.source_id")
      .where("import_id = ?",params[:import_id]).page(@page)
      render "index"

    end
    def import

#     Import.auto_import!
#    Similar.group_similar!
  
      #q = "music"
      #:page, :q
      @terms = ["headlines","dating", "tech","tennis","soccer","summer","open source software","software","dating","startup","acquired","music","entrepreneur","tech","business","education","fullerton","orange county","california"]
      if params[:news] && params[:news][:term]
        terms = [params[:news][:term]] #["dating"] #["tech"] #["dating"] #[nil,"tennis","soccer","summer","open source","software","dating","startup","acquired","music","entrepreneur","tech","business","education","fullerton","orange county","california"]
        terms.each do |term|
          Import.start_import({:max_pages=>1,:page=>1,:q=>term},current_user.id, logger, api_key:ENV["NEWS_API_KEY"])
        end

        redirect_to newsify.sources_import_path(step:2) #sources_path
      end
      @step = params[:step].to_i
  end

    private

    def setup_pager
      @page = params[:page] ? params[:page].to_i : 1
      @page = 1 if @page < 1
    end

  end

 

end