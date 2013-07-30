class CoverageViewerController < ApplicationController
	before_filter :ensure_user_signed_in
	
	def view_coverage_list
		bucket=storage.directories.new({:key => "taximagic-travis-artifacts"})
		@shas=bucket.files.collect{|fil| fil.key.split('/').first}.uniq.select{|sha| sha.match(/^[^\.]*$/)}
	end

	def s3_streamer
		bucket=storage.directories.new({:key => "taximagic-travis-artifacts"})
		filename = "#{params['sha']}/#{params['filename']}.#{params['ext']}"
		render text: bucket.files.get(filename).body, :content_type => content_type_for(filename)
	end

	private
		def content_type_for(filename)
			type = case filename.split(".").last
				when "html" then "text/html"
				when "js" then "text/javascript"
				when "css" then "text/css"
				else "text/html"
			end
			return type
		end

		def storage
			@storage ||= Fog::Storage.new({
			    :provider => "AWS",
			    :aws_access_key_id => ENV["AWS_S3_KEY"],
			    :aws_secret_access_key => ENV["AWS_S3_SECRET"],
				:region => ENV["AWS_S3_REGION"] || "us-east-1"
			})
			@storage
		end
end
