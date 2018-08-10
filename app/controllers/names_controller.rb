class NamesController < ApplicationController
	skip_before_action :verify_authenticity_token

	def update
		name = Name.create_or_update(name: params[:id], url: params[:url])
		render json: name
	end

	def show
		name = Name.find_by_name(params[:id])
		if name.present?
			attrs = name.attributes
			attrs.delete("id")
			render json: attrs
		else
			render json: {error: "not found", status: 404}, status: '404'
		end
	end

	def destroy_all
		Name.destroy_all
		render json: Name.all
	end

	def annotate
		data = request.body.read

		Name.all.each do |name|
			hash = Base64.encode64(name.url)
			data = data.gsub(`12, hash)
			data = data.gsub(/(\A|\s|>)#{name.name}(\W|\z)/) do |match|
				match.gsub(name.name, name.linkify)
			end
			data = data.gsub(hash, name.url)

		end

		render plain: data
	end

	






end