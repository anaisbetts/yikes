###########################################################################
#   Copyright (C) 2006 by Paul Betts                                      #
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

require 'config'
path_add File.join(File.dirname(__FILE__))

# Standard library
require 'rubygems'
require 'logger'
require 'gettext'
require 'pathname'
require 'fileutils'

include GetText

module Platform
class << self 
	def os
		return :linux if RUBY_PLATFORM =~ /linux/
		return :osx if RUBY_PLATFORM =~ /darwin/
		return :solaris if RUBY_PLATFORM =~ /solaris/
		return :bsd if RUBY_PLATFORM =~ /bsd/
		return :windows if RUBY_PLATFORM =~ /win/
	end

	def home_dir
		# FIXME: This is clearly wrong
		return 'C:\temp' if os == :windows

		ret = (ENV["HOME"] ? ENV["HOME"] : ".")
		return ret
	end

	def which(program)
		# FIXME: This is also clearly wrong
		return "" if os == :windows

		return `which #{program}`
	end

	def binary_dir
		return File.join(AppConfig::RootDir, 'bin')
	end

 	def logging_dir
 		# FIXME: Do I even need to say anything?
 		return "DONTKNOW" if os == :windows
 		return "/var/log"
 	end
 
 	def pidfile_dir
 		return "DONTKNOW" if os == :windows
 		return '/var/run'
 	end

	def settings_dir
		return "DONTKNOW" if os == :windows
		p = File.join(home_dir, ".yikes")
		`mkdir -p #{p}`
		return p
	end
 
 	def hostname
 		return "DONTKNOW" if os == :windows
 		return super_chomp(`hostname -s`)
 	end
 

end # Class << self
end

# Pull in OS-specific version of open3
require( (Platform.os != :windows) ? 'open3' : 'win32/open3')
