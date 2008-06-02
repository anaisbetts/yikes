# Copyright (c) 2008 Chris Wanstrath

# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in 
# the Software without restriction, including without limitation the rights to 
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
# the Software, and to permit persons to whom the Software is furnished to do so, 
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'platform'

class Command
	def initialize(block)
		(class << self;self end).send :define_method, :command, &block
	end

	def call(*args)
		arity = method(:command).arity
		args << nil while args.size < arity
		send :command, *args
	end

	def helper
		@helper ||= Helper.new
	end

	def options
		GitHub.options
	end

	def pgit(*command)
		puts git(*command)
	end

	def git(*command)
		sh ['git', command].flatten.join(' ')
	end

	def git_exec(*command)
		exec ['git', command].flatten.join(' ')
	end

	def sh(*command)
		Shell.new(*command).run
	end

	def die(message)
		puts "=> #{message}"
		exit!
	end

	class Shell < String
		def initialize(*command)
			@command = command
		end

		def run
			GitHub.debug "sh: #{command}"
			_, out, err = Open3.popen3(*@command)

			out = out.read.strip
			err = err.read.strip

			if out.any?
				replace @out = out
			elsif err.any?
				replace @error = err
			end
		end

		def command
			@command.join(' ')
		end

		def error?
			!!@error
		end

		def out?
			!!@out
		end
	end
end
