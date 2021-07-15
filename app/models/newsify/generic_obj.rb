module Newsify
module GenericObj
  extend ActiveSupport::Concern
  #include IconUtil, GraphBrowseUtil, GraphRateUtil, GraphEngageUtil #, FilterableObj, GraphSearchUtil

  def name_test
    "Hello world: #{self.name}"

  end
  def otype_guessed
    self.class.name.constantize.table_name.singularize
  end

  #TODO: reconcile/merge this with other universal otype methods
  def get_omni_update_otype
    if self.is_a?(Item)
        otype = "item"
      elsif self.is_a?(Describe)
        otype = "describe"
      elsif self.is_a?(Post)
        otype = "post"
      elsif self.is_a?(Idea)
        otype = "idea"
      elsif self.is_a?(User)
        otype = "user"
      else
        otype = nil
      end
  end


  #TODO: consider ways to make this quasi-dynamic
  #TODO: chekc for existence of /otypes/ext/row/#{self.otype_guessed}.html.erb
  # could have an optional param in each class, or field pulled from db
  def has_partial?
    #["item","post"]
    #["post"].include? self.otype_guessed
    false
  end

  # shared fieldds for re-using user interfaces
  def has_otype?
    return self.respond_to?(:otype)
  end

  # shared fieldds for re-using user interfaces
  def has_oid?
    return self.respond_to?(:oid)
  end

  def has_title?
    return self.respond_to?(:title)
  end  


  def upvotes_performed
    #TODO: loop through classes, get toggles of all upvotes?

    100
  end


  def created_at_span
       ActionController::Base.helpers.content_tag :span, class: 'time font-weight-bold border rounded' do
         self.created_at.strftime("%a %m/%d/%y") # Thu 3/19/20  # %l:%M %P = 1:06 am
       end
  end

  def creator_vague viewer
    if viewer.nil?
      "a student"
    else
      "a classmate"
    end
  end


  

  def created_at_wtime el_type = nil #{}"span"
      
      if el_type!="span" #.nil?
        output = created_at_date + " at " + created_at_time
      else
        # TODO: accomodate various wrappers
          output = created_at_date_span + " at " + created_at_time_span
      end

  end

    def updated_at_wtime el_type = nil # = "span"
      
      if el_type.nil?
        output = updated_at_date + " at " + updated_at_time
      else
        # TODO: accomodate various wrappers
          output = updated_at_date_span + " at " + updated_at_time_span
      end

    end

    def created_at_sortable
      self.created_at.strftime("%y-%m-%d")
    end
    
    def created_at_sortable_full
      self.created_at.to_datetime #.strftime("%Y-%m-%d") + " " + self.created_at.strftime("%l:%M%P")
    end

    def created_at_date
      self.created_at.strftime("%-m/%-d/%y")
    end
    def created_at_time
      self.created_at.strftime("%l:%M%P")
    end

    def updated_at_date
      self.updated_at.strftime("%-m/%-d/%y")
    end
    def updated_at_time
      self.updated_at.strftime("%l:%M%P")
    end


    def created_at_date_span fmt_class = "badge badge-white border rounded"
      ActionController::Base.helpers.content_tag :span, class: "date #{fmt_class}" do
         self.created_at.strftime("%-m/%-d/%y")
       end
    end
    def created_at_time_span fmt_class = "badge badge-primary"
      ActionController::Base.helpers.content_tag :span, class: "time #{fmt_class}" do
         self.created_at.strftime("%l:%M%P")
       end
    end

   
    def updated_at_date_span fmt_class = "badge badge-white border rounded"
      ActionController::Base.helpers.content_tag :span, class: "date #{fmt_class}" do
         self.updated_at.strftime("%-m/%-d/%y")
       end
    end
    def updated_at_time_span fmt_class = "badge badge-success"
      ActionController::Base.helpers.content_tag :span, class: "time #{fmt_class}" do
         self.updated_at.strftime("%l:%M%P")
       end
    end
end
end