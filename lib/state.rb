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
require 'thread'

include GetText

# This module contains the thread-safe state that we share with the web service thread
module ApplicationState
	attr_accessor :state

	def load_state(path)
		begin 
			@state = YAML::load(File.read(path))
		rescue
			@state = State.new
		end
	end

	def save_state(path)
		File.open(path, 'w') {|f| f.write(YAML::dump(@state)) }
	end

	class State
		attr_accessor :encoded_queue

		def initialize
			@encoded_queue = []
		end
	end
end


