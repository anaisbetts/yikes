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

require 'rubygems'
require 'logger'
require 'sync'
require 'thread'

ToEscape = [
	[ '\\', "\\\\" ],
	[ '"', "\"" ],
	[ '\'', "'" ],
	[ ',', "\\," ],
	[ '\'', "\\'" ],
	[ '-', "\\-" ],
	[ '(', "\\(" ],
	[ ')', "\\)" ],
	[ '&', "\\&" ],
	[ ' ', "\\ " ],
]
def escaped_path(path)
	ret = path.clone.to_s
	ToEscape.each { |x| ret.gsub!(x[0], x[1]) } ; ret
end

def super_chomp(s)
	s.gsub(/\W*$/, '').gsub!(/^\W*(\w.*)$/, '\1') || ''
end

def filelike?(path)
	p = Pathname.new(path)
	return false unless p.exist? and p.readable?
	return !(p.directory? or p.blockdev? or p.chardev?)
end

def get_file_list(path)
	Dir.glob(File.join(path, '**', '*')).delete_if {|x| not filelike?(x)}
end

def dump_stacks
	fork do
		ObjectSpace.each_object(Thread) do |th|
			th.raise Exception, "Stack Dump" unless Thread.current == th
		end
		raise Exception, "Stack Dump"
	end
end

# Metaid == a few simple metaclass helper
# (See http://whytheluckystiff.net/articles/seeingMetaclassesClearly.html.)
class Object
    # The hidden singleton lurks behind everyone
    def metaclass; class << self; self; end; end
    def meta_eval &blk; metaclass.instance_eval(&blk); end

    # Adds methods to a metaclass
    def meta_def name, &blk
        meta_eval { define_method name, &blk }
    end
end

class Module
    # Defines an instance method within a module
    def module_def name, &blk
        module_eval { define_method name, &blk }
    end
end

class Class
    alias class_def module_def
end

