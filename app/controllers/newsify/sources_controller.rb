module Newsify
  class SourcesController < ApplicationController
    include Newsify::ClassifyNews

    before_action :setup_pager
    before_action :set_source, only: [:show, :opinions]

    def index
      
      #Newsify::Cache.set_obj "my_test_key", "hello"
      #@cache_result = Newsify::Cache.get_obj "my_test_key"

      @labeled = Source.order("created_at DESC")
      .page(@page).per(20)
    end

    def show
      impression = impressionist(@source, "",{},{})
      do_summarization! if params[:summarize]

      @new_comment    = Comment.build_from(@source, current_user.id, "")

    end

    def opinions

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

    def set_source
      @source = Source.find_by(id:params[:id])
    end


    def setup_pager
      @page = params[:page] ? params[:page].to_i : 1
      @page = 1 if @page < 1
    end

    def do_summarization!      
      @testing = 123
      if params[:clean]
        @purging = @source.purge_duplicate_topics
      end

      if params[:summarize] 
        summary_count = @source.summary_count
        if summary_count == 0
          @summarize_result = Classify::Summarize.from_sources @source
        end
      end

      source_hash_string = {:site=>"localhost",:table=>"sources",:id=>@source.id,:user_id=>0}.to_json.to_s
      @hashkey = Digest::SHA256.hexdigest(source_hash_string)

      if @source.first_content.nil?
        if params[:get_url]
          url = @source.url
          preview = @source.description
          n = 4
          preview = preview.split[0...n].join(' ')
          @output = Content.from_web(url,preview,logger)
          Content.save_content(@source,@output)
        end
      else
        @output = @source.first_content.misc #.nil? ? nil : JSON.parse(@content.misc)
      end

    end

  end

 

end