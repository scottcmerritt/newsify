module Community
class GuessScope < ActiveRecord::Base
	self.table_name = "guess_scopes"
	
	def self.accuracy user, details = false
		true_vals = GuessScope.where(user_id:user.id,accurate: true).count
		false_vals = GuessScope.where(user_id:user.id,accurate: false).count
		if (true_vals+false_vals) == 0
			return nil
		else
			accuracy = true_vals.to_f / (true_vals + false_vals)
			if details
				return {true: true_vals,false:false_vals,accuracy: accuracy}
			else
				return accuracy
			end
		end
	end

	def reason_text
		return nil if self.reason.nil?
		reason_json = JSON.parse(self.reason)
		items = reason_json["items"]
		if items.nil?
			return "No explanation"
		else
			txt = []
			items.each do |k,v|
				item = Item.find_by(id: k)
				txt.push item.name
			end
			return txt.split(", ")
		end
	end

	def self.log_vote! target:, user:, scope:, value:
		gs = GuessScope.where(user_id:user.id,target_type:target.class.name,target_id:target.id,scope:scope).first
		unless gs.nil?
			gs.accurate = (gs.score > 5 && value == true) || (gs.score <=0 && value == false)
			gs.save
		end
	end

end
end