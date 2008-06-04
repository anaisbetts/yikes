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
require 'yaml'
require 'digest/md5'

include GetText

# TODO: We may make this customizable later
ItemsInFinishedList = 30

# This module contains the thread-safe state that we share with the web service thread
# TODO: The name 'state' is completely retarded
module ApplicationState
	attr_accessor :state

	def load_state(path, library)
		# If they give us a bum path, we can't get the real path
		real_lib = nil
		begin
			real_lib = Pathname.new(library).realpath.to_s
		rescue
			real_lib = library
		end

		begin 
			# We hold a different State class for every library path
			@full_state = YAML::load(File.read(path))
			@state = @full_state[real_lib] || (@full_state[real_lib] = State.new(library))
		rescue
			@full_state = { real_lib => State.new(library) }
			@state = @full_state[real_lib]
		end
	end

	def save_state(path)
		File.open(path, 'w') {|f| f.write(YAML::dump(@full_state)) }
	end

	class State
		attr_accessor :encoded_queue
		attr_accessor :to_encode_queue
		attr_accessor :library
		attr_accessor :target 

		def initialize(library)
			@encoded_queue = []
			@to_encode_queue = []
			@encoded_queue_lock = Mutex.new
			@to_encode_queue_lock = Mutex.new
			@library = library
		end

		def add_to_queue(items, prepend = false)
			@to_encode_queue_lock.synchronize {
				items.each {|x| (prepend ? @to_encode_queue.unshift(x) : @to_encode_queue << x) }
			}
		end

		def dequeue_items(count = 1)
			ret = []
			@to_encode_queue_lock.synchronize {
				count.times do |x|
					break if @to_encode_queue.empty?
					ret << @to_encode_queue.shift
				end
			}
			return ret
		end

		def items_count
			ret = 0
			@to_encode_queue_lock.synchronize {
				ret = @to_encode_queue.length
			}
			ret
		end

		def encode_succeeded!(item)
			item.succeeded = true
			add_to_finished_list item
		end


		def encode_failed!(item)
			item.succeeded = false
			add_to_finished_list item
		end
		
		def add_to_finished_list(item)
			item.finished_at = Time.now
			@encoded_queue_lock.synchronize {
				@encoded_queue << item
				break if @encoded_queue.length <= ItemsInFinishedList
				
				@encoded_queue = @encoded_queue.last(ItemsInFinishedList)
			}
		end

		def get_finished_items
			# Make a shallow copy so we don't have to hold the lock for so long
			ret = nil
			@encoded_queue_lock.synchronize {
				ret = Array.new(@encoded_queue)
			}

			ret
		end
	end
end

class EncodingItem
	attr_accessor :subpath, :succeeded, :created_at, :finished_at, :library, :target

	# This is only so we can Yaml'ify!
	def initialize
	end

	def initialize(library, source_path, target)
		(@library, @subpath, @target, @succeeded) = [library, EncodingItem.extract_subpath(library, source_path), target, false]
		@created_at = Time.now
	end

	def source_path
		File.join(@library, @subpath)
	end

	def target_path
		EncodingItem.build_target_path(@target, @subpath)
	end

	def subpath_target
		EncodingItem.subpath_as_target_ext(@subpath)
	end

	def screenshot_path
		File.join Platform.screenshot_dir, screenshot_subpath
	end

	def screenshot_subpath
		md = Digest::MD5.new << @subpath
		md.to_s + ".jpg"
	end

class << self
	def extract_subpath(source_root, file)
		return file unless file.index(source_root) == 0 and not source_root.empty?
		file.sub(File.join(source_root, ''), '')
	end

	def build_target_path(target_root, subpath, target_ext = "mp4")
		File.join(target_root, subpath_as_target_ext(subpath, target_ext))
	end

	def subpath_as_target_ext(subpath, target_ext = "mp4")
		subpath.gsub(/\.[^\.\/\\]*$/, ".#{target_ext}")
	end
end
end
