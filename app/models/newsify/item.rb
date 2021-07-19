module Newsify
class Item < ActiveRecord::Base #AbstractModel  #ActiveRecord::Base Labeled
	self.table_name = "items"
	is_impressionable if defined?(is_impressionable)

	def self.model_name
  		ActiveModel::Name.new("Newsify::Item", nil, "Item")
	end

	acts_as_votable
	include Community::VoteCacheable, Community::IconUtil, Classify::ClassifyContent

=begin
  has_merit

	include GenericObj, IconUtil, ClassifyContent
	include PgSearch::Model
	include VoteCacheable
	has_merit
	acts_as_votable
	acts_as_favoritable
	resourcify

	#has_friendship # users can LIKE items, to add interests to their profile

	has_many :rooms
	has_many :orgs, class_name: "Community::Org"
	belongs_to :room, optional: true

	has_many :source_topics, dependent: :destroy,
                           inverse_of: :item



  # tsearch params
  # negation:true can be added to tsearch, then any term with an ! before it will be negated
 # dictionary: "english" will add stemming, "jumped" and "jumping" will be grouped together, otherwise diction: "simple" is used by default
	# normalization: (choose one), 0,1,2,4,8,16,322 see deetails here: https://github.com/Casecommons/pg_search
  multisearchable against: [:name, :wiki_text], 
                    using: {
                    tsearch: { prefix: true,dictionary: "english",highlight: {
                        StartSel: '<b>',
                        StopSel: '</b>',
                        MaxWords: 123,
                        MinWords: 456,
                        ShortWord: 4,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      } },:trigram => {},:dmetaphone => {} },:ignoring => :accents 
  
  pg_search_scope :kinda_spelled_like,
                  against: :name
                  #,ignoring: :accents

  #pg_search_scope :kinda_spelled_like,
  #                against: :name,
  #                using: :trigram

	# via = using it as the filter

=end	

	scope :all_sounds, -> { where("items.itype = ?", "SOUND")}
	scope :all_people, -> { where("items.itype = ?", "PERSON")}
	scope :by_itype, -> (itype) { where("items.itype = ?", itype)}
	
	def has_org?
		Community::Org.exists?(item_id:self.id)
	end

	def self.basic_search q
		query = "%#{q}%"
		where("name LIKE ?", query)
	end


	def post_count
		source_topics.count
	end
	def rooms_as_ammo
		Room.where(id:RoomPreview.where(preview_type:"Item",preview_id:self.id).pluck(:room_id))
	end

	def otype_guessed
		"item"
	end
	def title
		self.name
	end
	def content
		self.wiki_text
	end
	def otitle
		self.name
	end	
	def oname
		self.name
	end
	def audio?
		self.itype == "SOUND" && !self.url.blank?
	end


	def audio_json
		self.to_json(:only=>[:id,:name,:url])
	end

	def parent
		Item.find_by(id:self.parent_id)
	end
=begin
	# this is called by to_json, so override as_json
	def as_json(options)
  		extra = {title: "Test title"} # {user.gravatar_url,sender_name:user.username}
    	#extra[:room_name] = self.room.name if self.show_room
    	super(options).merge(extra) #.except(:show_room)
  	end

	def to_json
		#super(:only => :username, :methods => [:foo, :bar])
		super(:only => [:id,:title], :methods => [:oname, :otitle])
	end
=end

	# comes in the format /News/Politics
	# look at itype "CATEGORY"
	def self.by_google_category label
		parts = label.split("/")[1..-1]
		return Item.joins("LEFT JOIN items i2 ON i2.id = items.parent_id").where("LOWER(items.name) = ? AND LOWER(i2.name) = ? AND items.itype = ? AND i2.itype = ?",parts[-1].downcase,parts[-2].downcase,"CATEGORY","CATEGORY").first if parts.length > 1
		return Item.where("itype = ? AND LOWER(name) = ?","CATEGORY",parts[-1].downcase).first if parts.length > 0
		nil
	end


	def self.top_categories category="interesting", itype = nil, limit = 4
		Item.points_by_category(category, itype).limit(limit)
	end
	def top_categories catgegory = "interesting", limit = 4
		Item.points_by_category(category, nil, self.id).limit(limit)
	end

	def self.points_by_category category, itype = nil, parent_id = nil

  		points = Item.select("items.id,items.name,items.itype,sum(msp.num_points) as total_points,ms.category")
		.joins("LEFT JOIN merit_scores ms ON ms.sash_id = items.sash_id")
		.joins("LEFT JOIN merit_score_points msp ON msp.score_id = ms.id")
		.group("items.id,ms.category")
		.order("sum(msp.num_points) DESC")
		.where("NOT msp.num_points = 0")
		points = points.where(itype: itype) unless itype.nil?
		points = points.where(parent_id: parent_id) unless parent_id.nil?
		points = points.where("ms.category = ?",category) unless category.nil?

		points
  	end

end
end