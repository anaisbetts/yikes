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

$:.unshift File.join(File.dirname(__FILE__))

require 'config'

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

		homedir = (ENV["HOME"] ? ENV["HOME"] : ".")
		ret = File.join(homedir, ".estelle")

		FileUtils.mkdir_p(ret) unless Pathname.new(ret).exist?
		return ret
	end

	def which(program)
		# FIXME: This is also clearly wrong
		return "" if os == :windows

		return `which #{program}`
	end

	def settings_file_path
		return File.join(home_dir, "settings.yaml")
	end

	def binary_dir
		return File.join(AppConfig::RootDir, 'bin')
	end

end # Class << self
end
