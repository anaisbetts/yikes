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
require 'rbconfig'

# Yikes
require 'utility'

include GetText

module Platform
class << self 

	def run_external_command_fork(cmd)
		# FIXME: Dumb hack code!
		pid = nil
		unless (pid = fork)
			STDIN.reopen '/dev/null'
			STDOUT.reopen '/dev/null'
			STDERR.reopen '/dev/null'
			logger.debug "Executing: #{cmd}"
			before_transcode() if self.respond_to? :before_transcode
			system(cmd)
			after_transcode() if self.respond_to? :before_transcode
			Kernel.exit!
		end
		e = Process.wait pid
		exitcode = ($?) ? ($?.exitstatus) : -1
		logger.info "Process returned #{exitcode}"
	end

	def run_external_command(cmd)
		logger.debug "Running #{cmd}"

		if platform_has_fork?
			run_external_command_fork(cmd) 
			return true
		end

		# Last chance - just use system
		system(cmd)
		return true

#                 IO.popen cmd do |i,o,e|
#                         break
#                         o.readlines.each do |line|
#                                 p line
#                         end
#                 end

#		if Platform.os == :windows
#			# TODO: Implement me
#			return
#		end
#
#		# Platform is Posix so we have fork
#		Kernel.fork do
#			before_transcode() if self.respond_to? :before_transcode
#			Kernel.exec 
#			after_transcode() if self.respond_to? :before_transcode
#		end
	end

 	def hostname
		# NOTE: Apparently hostname -s doesn't do what the man page says it does;
		# on some machines it returns 'localhost'
 		return "DONTKNOW" if os == :windows
		return super_chomp(`hostname`.gsub(/^[\.]*\..*$/, '\1'))
 	end


	###
	# Constant-returning routines (aka "boring")
	###

	def ruby_runtime
		# FIXME: Rubinius? IronRuby?
		return :jruby if RUBY_PLATFORM =~ /java/
		return :mri
	end

	def os
		host_os = Config::CONFIG['host_os']
		return :linux if host_os =~ /linux/
		return :osx if host_os =~ /darwin/
		return :solaris if host_os =~ /solaris/
		return :bsd if host_os =~ /bsd/
		return :windows if host_os =~ /win/
	end

	def platform_has_fork?
		os != :windows and [:mri, :rubinius].include? ruby_runtime
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
		path = File.join(home_dir, ".yikes")
		FileUtils.mkdir_p path
		return path
	end

	def screenshot_dir
		path = File.join(Platform.settings_dir, 'preview')
		FileUtils.mkdir_p path
		return path
	end
 

end # Class << self
end

# Pull in OS-specific version of open3
require( (Platform.os != :windows) ? 'open3' : 'win32/open3')
