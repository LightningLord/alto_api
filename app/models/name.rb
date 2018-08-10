class Name < ActiveRecord::Base

	def self.create_or_update(params)
		name = self.find_by_name(params[:name])
		if name.present?
			name.update_attributes(url: params[:url])
		else
			name = self.create(name: params[:name], url: params[:url])
		end
		attrs = name.attributes 
		attrs.delete("id")
		attrs
	end

	def linkify
		'<a href="' + self.url + '">' + self.name + '</a>'
	end


end