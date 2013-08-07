require 'zlib'
require 'rubygems/package'

class CoverageViewerController < ApplicationController
	before_filter :ensure_user_signed_in
	
	def view_coverage_list
		bucket=storage.directories.new({:key => S3_BUCKET})
		reports = bucket.files.select{|file| !file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*$/).nil?}
		triplets = reports.map { |report| report.key.split("_") }
		@coverage_hash = triplets.reduce({}) do |memo, array|
			memo[array[1]] ||= []
			memo[array[1]] << [array.first, array.last]
			memo
		end
	end

	def s3_streamer
		#would probably make more sense to just cache the file contents themselves in the cache
		bucket=storage.directories.new({:key => S3_BUCKET})
		unless targz=Rails.cache.read(params['sha'])
			file=bucket.files.detect{|file| !file.key.match(params['sha']).nil?}
			Rails.cache.write(params['sha'], file.body) unless file.nil? 			
			targz=file.body
		end
		tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(targz)))
		file = nil		
		filename = "#{params['filename']}.#{params['ext']}"
		tar_extract.each do |entry|
			file = entry.read if entry.full_name.split('/').last == filename
  		end
		tar_extract.close
		render text: file, :content_type => content_type_for(filename)
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
			@storage ||= Fog::Storage.new({:provider => "AWS",:aws_access_key_id => ENV["AWS_S3_KEY"],:aws_secret_access_key => ENV["AWS_S3_SECRET"],:region => ENV["AWS_S3_REGION"] || "us-east-1"})
			@storage
		end
end
