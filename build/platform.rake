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

def os
	return :linux if RUBY_PLATFORM =~ /linux/
	return :osx if RUBY_PLATFORM =~ /darwin/
	return :solaris if RUBY_PLATFORM =~ /solaris/
	return :bsd if RUBY_PLATFORM =~ /bsd/
	return :windows if RUBY_PLATFORM =~ /win/
end

def get_install_prefix
	# FIXME: Win32 is broken
	ret = ENV["PREFIX"]
	return ret if ret and ret.length > 0
	return "/usr/local"
end

def libname(file)
	return "#{file}.dll" if os() == :win32
	return "#{file}.so" if os() == :linux
	return "#{file}.dylib" if os() == :osx
end

def require_os(file)
	begin
		require "#{file}_#{os.to_s}"
	rescue
		puts "Foo"
	end
end

def load_os(file)
	begin
		load "#{file}_#{os.to_s}"
	rescue
		puts "Foo"
	end
end

def ruby_path
	return ENV["RUBY_BIN"] if ENV["RUBY_BIN"]

	# FIXME: We need to include Ruby on Win32
	return nil if os() == :win32
	ret = `where ruby`
	return ($? != 0 ? ret : nil)
end
