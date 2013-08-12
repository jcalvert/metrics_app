require 'zlib'
require 'nokogiri'
require 'rubygems/package'

class CoverageViewerController < ApplicationController
	before_filter :ensure_user_signed_in
	
	def view_coverage_list
		persist_all_reports
		@reports = CoverageReport.all.reduce({}) do |memo, report|
			memo[report.repo] ||= []
			memo[report.repo] << report
			memo
		end
		@reports.values.each do |repo_array| 
			repo_array.sort!{|report1, report2| report1.publication_date <=> report2.publication_date}
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
			unless targz=Rails.cache.read(sha)
				targz_file=bucket.objects.detect{|bucket_file|!bucket_file.key.match(sha).nil?}
				raise NotFoundError if targz_file.nil? 
				targz=targz_file.read	
				Rails.cache.write(sha, targz)						
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

		def persist_all_reports
			#temporary till builds that push all files rotate out
			to_kill = bucket.objects.select do |file|
				file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*$/).nil? && 
				file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*_travis_branch_*$/).nil?
			end
			to_kill.each{|f| f.delete}
			reports = bucket.objects.select do |file| 
				!file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*$/).nil? ||
				!file.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*_travis_branch_*$/).nil?
			end
			known_reports = CoverageReport.all.collect{|report| report.key}
			reports.each{|report| 
				persist_report(report) unless known_reports.include?(report.key)
			}
		end

		def persist_report(report)
			if !report.key.match(/^[a-z0-9]*_[a-zA-Z0-9\/]*_[0-9]*_travis_branch_*$/).nil?
				first, second = report.key.split("_travis_branch_")
			else
				first, second = report.key, nil
			end
			sha, repo, build_id = first.split("_")
			return unless sha && repo && build_id # skip things that don't match the pattern in the bucket
			coverage = extract_percentage(sha).chop 
			CoverageReport.create(:sha => sha, :repo => repo, :build_id => build_id, :coverage => coverage, 
				:key => report.key, :publication_date => report.last_modified, :branch => second)
		end

		def extract_percentage(sha)
			coverage_index = get_file("index.html", sha)
			doc = Nokogiri::HTML(coverage_index)
			doc.xpath('//*[@id="report_table"]/tfoot/tr/td[4]/div[1]').first.content
		end

		def bucket
			@bucket ||= AWS::S3.new.buckets[S3_BUCKET]
			@bucket
		end

		class NotFoundError < StandardError
		end
end
