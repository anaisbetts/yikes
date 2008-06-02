###########################################################################
#   Copyright (C) 2008 by Paul Betts                                      #
#   paul.betts@gmail.com                                                  #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################

require File.join(File.dirname(__FILE__), 'config')
path_add File.join(File.dirname(__FILE__))

# Standard library
require 'rubygems'
require 'logger'
require 'gettext'
require 'yaml'
require 'ramaze'
require 'builder'
require 'builder/xmlmarkup'

# Yikes
require 'config'
require 'platform'
require 'utility'
require 'state'

include GetText

Ramaze::Global.public_root = File.join AppConfig::RootDir, 'public'

class MainController < Ramaze::Controller
	def index
		'Hello, world!'
	end
end

class PodcastController < Ramaze::Controller
	map '/podcast'

	def index
		return podcast_xml
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

class FilesController < Ramaze::Controller
	map '/files'

	def index(*paths)
		do_send_file File.join(paths)
	end

private
	def do_send_file(subpath)
		target = Yikes.instance.state.target
		p = Pathname.new(File.join(target, subpath))
		begin
			return nil unless p.realpath.to_s.index(target) == 0
		rescue
			return nil
		end
		logger.debug p.to_s
		send_file(p.to_s, 'video/mp4')
	end
end
