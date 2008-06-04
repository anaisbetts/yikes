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
require 'fileutils'

# Yikes
require 'config'
require 'platform'
require 'utility'
require 'state'

include GetText

Ramaze::Global.public_root = File.join AppConfig::RootDir, 'public'
Ramaze::Global.template_root = File.join AppConfig::RootDir, 'views'

### Helper Classes

# FIXME: This creates a broken mapping to /static_file
class StaticFileControllerBase < Ramaze::Controller 
	def index(*paths)
		do_send_file File.join(paths)
	end

protected

	def do_send_file(subpath)
		target = get_file_path
		mimetype = get_mime_type
		p = Pathname.new(File.join(target, subpath))
		begin
			return nil unless p.realpath.to_s.index(target) == 0
		rescue
			return nil
		end
		logger.debug p.to_s
		send_file(p.to_s, mimetype)
	end

	def get_mime_type; 'video/mp4'; end
end

class EncodingItem
	def source_url
		"#{Yikes.url_base}/files/#{subpath_target}"
	end

	def screenshot_url
		"#{Yikes.url_base}/preview/#{screenshot_subpath}"
	end
end

### Controllers

class MainController < Ramaze::Controller
	engine :Erubis

	def index
		@items = Yikes.instance.state.get_finished_items
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
			xml.link Yikes.url_base
			xml.language "en-us"
			xml.copyright "Copyright 2008 Paul Betts"
			xml.tag! "itunes:summary", "Converted videos, from #{app.library}"
			xml.description "Converted videos, from #{app.library}"
			xml.tag! "itunes:image", "#{Yikes.url_base}/FILLMEIN.png"
			xml.tag! "itunes:category", "Videos"

			app.get_finished_items.each do |x|
				xml.item do
					next unless x.succeeded
					xml.title x.subpath
					xml.tag! "itunes:subtitle", x.source_path
					xml.enclosure(:url => x.source_url, :length => "100000", :type => "video/mp4")
					xml.guid x.source_url
					xml.pubDate x.finished_at.to_s
					xml.tag! "itunes:duration", "3:00"
				end 
			end
		end ; end

		xml.target!
	end
end

class FilesController < StaticFileControllerBase
	map '/files'

protected
	def get_file_path
		Yikes.instance.state.target
	end
end

class PreviewController < StaticFileControllerBase
	map '/preview'

protected
	def get_file_path
		Platform.screenshot_dir
	end

	def get_mime_type; 'image/jpeg'; end
end

