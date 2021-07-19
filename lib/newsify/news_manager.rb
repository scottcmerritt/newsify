module Newsify
# shared functionality for news related classes
module NewsManager
  # NOTE: this next line was commented out, not sure if that was intentional
  extend ActiveSupport::Concern

   # this is a method thats called when you include the module in a class.
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # accesed by Post.flags, Post.flagged_spam, etc...

    def flags #self.flags
      {1 => "spam", 2=> "obscene", 3=> "harassment",0 => "ok"}
    end

  end

  def oid guess_oid
    # default is to guess
    guess_oid = guess_oid == false ? false : true
    if has_oid?
      self.oid
    elsif guess_oid
      self.id
    else
      nil
    end
  end

  # guesses the otype if none is specified
  def otype_guessed
    # default is to guess
    guess_otype = guess_otype == false ? false : true

    if has_otype?
      self.otype
    else 
      self.class.to_s.downcase #{}"guess"
    end
  end

  def has_customotype?
    self.respond_to?(:customotype) && !self.customotype.blank?
  end



   # shared fieldds for re-using user interfaces
  def has_otype?
    return self.respond_to?(:otype)
  end

  # shared fieldds for re-using user interfaces
  def has_oid?
    return self.respond_to?(:oid)
  end


  def created_by_id
    self.respond_to?(:createdby) ? self.createdby : self.created_by
  end

  def can_edit? user
    self.is_a?(Source) ? false : (!user.nil? && self.created_by_id == user.id)
  end

  def source_groups
    SourceGroup.where(source_id: self.id)
  end

  
end

end