module Newsify
module ClassifyNews
  # shared functionality for news related controller
  extend ActiveSupport::Concern

   
  included do
    #before_action :method_here

  end


  def similar
    @similar, @sources, @new_group_ids = Classify::Similar.group_similar! params[:run], params[:save]

    @sources = @sources.page(params[:page]).per(10)

    # undoes grouping
    
    #Source.all.update_all(is_group: false,group_id: nil)
    #SourceGroup.all.destroy_all

    @grouped = Newsify::Source.where(is_group: true).order("created_at DESC").page(params[:page]).per(20)
    @source_groups = Newsify::SourceGroup.limit(20)
    #@grouped = Source.select("sources.*")
    #.joins("LEFT JOIN source_groups sg ON sg.child_id = sources.id")
    #.limit(20)
  end

  # does classification in the background if xhr? 
  # or does it before returning result to browser
  def import_classify
    @classified = []
    @items = []
    @errors = []
    
    @import = Import.find_by(id:params[:import_id])
    request.xhr? && @import.respond_to?(:delay) ? @import.delay.classify! : do_import_classify

    respond_to do |format|
        format.html {render "import_classify"}
        format.js {render "import_classify.js"}
        #format.json {render :json => {data: @import}}
    end
  end

  def do_import_classify
     ga = GoogleAnalyze.new

      @import.import_sources.each do |import_source|
          source = import_source.source
          if source.topics.length == 0
            res = source.google_classify! entities: true, min_salience: 0.01, ga: ga
            @items = @items + res[:rows]
            @errors = @errors + res[:errors]
            @classified.push source.id
          end
      end

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
          Import.start_import({:max_pages=>1,:page=>1,:q=>term},current_user.id, logger)
        end

        redirect_to sources_import_path(step:2) #sources_path
      end
      @step = params[:step].to_i
  end


  private

 
end
end