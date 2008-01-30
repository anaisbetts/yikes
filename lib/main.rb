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
require 'optparse'
require 'optparse/time'
require 'highline'
require 'singleton'
require 'yaml'

# Yikes
require 'platform'
require 'config'
require 'utility'
require 'engine'

include GetText

$logging_level = ($DEBUG ? Logger::DEBUG : Logger::ERROR)

class Yikes < Logger::Application
	include Singleton

	def initialize
		super(self.class.to_s) 
		self.level = $logging_level
	end

	def parse(args)
		# Set the defaults here
		results = { :target => 'iPod', :library => '.' }

		opts = OptionParser.new do |opts|
			opts.banner = _("Usage: Yikes [options]")

			opts.separator ""
			opts.separator _("Specific options:")

			opts.on('-l', _("--dslibrary /path/to/videos"),
				_("Directory to recursively scan for videos")) do |x|
				results[:library] = x 
			end

			opts.on('-t', "--target dir", _("Directory to put files in")) do |x|
				results[:target] = x
			end

			opts.on('-g', '--gui', _("Run the GUI version of this application")) do |x|
				results[:rungui] = true
			end

			opts.separator ""
			opts.separator _("Common options:")

			opts.on_tail("-?", "--help", _("Show this message") ) do
				puts opts
				exit
			end

			opts.on('-d', "--debug", _("Run in debug mode (Extra messages)")) do |x|
				$logging_level = DEBUG
			end

			opts.on('-v', "--verbose", _("Run verbosely")) do |x|
				$logging_level = INFO 
			end

			opts.on_tail("--version", _("Show version") ) do
				puts OptionParser::Version.join('.')
				exit
			end
		end

		opts.parse!(args);	results
	end

	def run
		# Initialize Gettext (root, domain, locale dir, encoding) and set up logging
    		bindtextdomain(AppConfig::Package, nil, nil, "UTF-8")
		self.level = Logger::DEBUG
		
		# If we're called with no arguments, run the GUI version
		if ARGV.size == 0
			run_gui
			exit
		end

		# Parse arguments
		begin
			results = parse(ARGV)
		rescue OptionParser::MissingArgument
			puts _('Missing parameter; see --help for more info')
			exit
		rescue OptionParser::InvalidOption
			puts _('Invalid option; see --help for more info')
			exit
		end

		# Reset our logging level because option parsing changed it
		self.level = $logging_level

		# Run the GUI if requested
		log DEBUG, 'Starting application'
		if results[:rungui]
			run_gui
			exit
		end

		# Hey here's the real code!
		io = HighLine.new
		engine = Engine.new
		get_file_list(results).each {|x| engine.convert_file_and_save(results[:library], x, results[:target])}

		log DEBUG, 'Exiting application'
	end

	def get_file_list(optparse)
		Dir.glob(File.join(optparse[:library], '**', '*')).delete_if {|x| not filelike?(x)}
	end

	def run_gui
		#$:.unshift File.join(File.dirname(__FILE__), 'gtk-ui')

		log DEBUG, 'Starting GUI...'
		throw "Implement the GUI!"
		#Gtk.init
		#Gnome::Program.new(Config::Package, Config::Version)
		#main_window = MainWindow.new
		#Gtk.main
	end
end

return unless __FILE__ == $0

$the_app = Yikes.instance
$the_app.run
