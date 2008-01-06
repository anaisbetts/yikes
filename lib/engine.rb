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

# Standard library
require 'rubygems'
require 'logger'
require 'gettext'
require 'singleton'
require 'fileutils'
require 'pathname'
require 'yaml'

# Yikes
require 'platform'
require 'config'
require 'utility'

include GetText

$logging_level ||= Logger::ERROR

#puts Engine.instance_methods if defined? Engine

class Engine 
	def initialize
		#super(self.class.to_s)
		#self.level = $logging_level
	end

	# Main function for converting a video file and writing it to a folder
	# /some/root/Folder/file.avi => /target/Folder/file.mp4
	def convert_file_and_save(source_root, file_path, target_root)
		dest_file = Pathname.new(build_target_path(extract_subpath(source_root, file_path), target_root))
		FileUtils.mkdir_p(dest_file.dirname)
		transcode_if_exists(file_path, dest_file)
	end

	TranscodeScript = File.join(AppConfig::RootDir, 'bin', 'ffmpeg_run.sh')
	def transcode_if_exists(input, output)
		true if Pathname.new(output).exist?
		system(TranscodeScript, input, output)
	end

class << self
	def extract_subpath(source_root, file)
		file.gsub(File.join(source_root, ''), '')
	end

	def build_target_path(subpath, target_root, target_ext = "mp4")
		File.join(target_root, subpath.gsub(/\.[^\.\/\\]*$/, ".#{target_ext}"))
	end
end

end
