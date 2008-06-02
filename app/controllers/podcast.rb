require 'builder'
require 'builder/xmlmarkup'

class Podcast < Application
	def index
		render podcast_xml, :layout => false
	end

	def send_file
		target = Yikes.instance.state.target
		p = Pathname.new(File.join(target, params["path"]))
		return p.to_s
		begin
			return nil unless p.realpath.to_s.index(target) == 0
		rescue
			return nil
		end
		p.to_s
		#send_file(File.open(p.to_s, 'r'))
	end

private
	def podcast_xml
		app = Yikes.instance.state
		
		xml = Builder::XmlMarkup.new
		xml.instruct!

		xml.rss("xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd", "xmlns:media" => "http://search.yahoo.com/mrss/", "version" => "2.0") do

		xml.channel do
			xml.title "Yikes video feed of #{Pathname.new(app.library).basename.to_s}"
			xml.link url_base
			xml.language "en-us"
			xml.copyright "Copyright 2008 Paul Betts"
			xml.tag! "itunes:summary", "Converted videos, from #{app.library}"
			xml.description "Converted videos, from #{app.library}"
			xml.tag! "itunes:image", "#{url_base}/FILLMEIN.png"
			xml.tag! "itunes:category", "Videos"

			app.get_finished_items.each do |x|
				xml.item do
					next unless x.succeeded
					xml.title x.subpath
					xml.tag! "itunes:subtitle", x.source_path
					xml.enclosure(:url => "#{url_base}/files/#{x.subpath}", :length => "100000", :type => "video/mp4")
					xml.guid "#{url_base}/#{Platform.hostname}.local/files/#{x.subpath}"
					xml.pubDate x.finished_at.to_s
					xml.tag! "itunes:duration", "3:00"
				end 
			end
		end ; end

		xml.target!
	end

	def url_base
		"http://#{Platform.hostname}.local:4000"
	end
end
