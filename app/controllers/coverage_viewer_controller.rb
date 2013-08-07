require 'zlib'
require 'nokogiri'
require 'rubygems/package'

class CoverageViewerController < ApplicationController
	before_filter :ensure_user_signed_in
	
	def view_coverage_list
		bucket=storage.directories.new({:key => S3_BUCKET})
		reports = bucket.files.select{|file| !file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*$/).nil?}
		triplets = reports.map { |report| report.key.split("_") }
		#TODO: create a model for coverage reports
		@coverage_hash = triplets.reduce({}) do |memo, array|
			memo[array[1]] ||= []
			coverage_index = get_file("index.html", array.first)
			doc = Nokogiri::HTML(coverage_index)
			percent = doc.xpath('//*[@id="report_table"]/tfoot/tr/td[4]/div[1]').first.content
			memo[array[1]] << [array.first, percent, array.last]
			memo
		end
	end

	def s3_streamer
		filename = "#{params[:filename]}.#{params[:ext]}"
		render text: get_file(filename, params[:sha]), :content_type => content_type_for(filename)
	end

	private
		def get_file(filename, sha)
			file=Rails.cache.read("#{sha}/#{filename}")
			return file unless file.nil?
			bucket=storage.directories.new({:key => S3_BUCKET})
			unless targz=Rails.cache.read(sha)
				targz_file=bucket.files.detect{|bucket_file|!bucket_file.key.match(sha).nil?}
				raise NotFoundError if targz_file.nil? 	
				Rails.cache.write(sha, targz_file.body)		
				targz=targz_file.body
			end
			tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.new(StringIO.new(targz)))
			tar_extract.each do |entry|
				file = entry.read if entry.full_name.split('/').last == filename
	  		end
			tar_extract.close
			Rails.cache.write("#{sha}/#{filename}", file)
			return file
		end

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

		class NotFoundError < StandardError
		end
end
