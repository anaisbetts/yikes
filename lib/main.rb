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

$:.unshift File.join(File.dirname(__FILE__))

# Standard library
require 'config'
require 'rubygems'
require 'logger'
require 'gettext'
require 'optparse'
require 'optparse/time'
require 'highline'

# Estelle
require 'platform'
require 'config'
require 'utility'

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
		results = { :target => '.' }

		opts = OptionParser.new do |opts|
			opts.banner = _("Usage: Estelle [options]")

			opts.separator ""
			opts.separator _("Specific options:")

			opts.on('-l', _("--library /path/to/videos"),
				_("Directory to recursively scan for videos")) do |x|
				results[:dir] = x 
			end

			opts.on('-t', "--target dir", _("Directory to put music in")) do |x|
				results[:target] = x
			end

			opts.on('-g', '--gui', _("Run the GUI version of this application")) do |x|
				results[:rungui] = true
			end

			opts.separator ""
			opts.separator _("Common options:")

			opts.on_tail("-h", "--help", _("Show this message") ) do
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

		io = HighLine.new

		# Figure out a list of files to load
		file_list = []
		if results.has_key? :dir
			file_list = filelist_from_root results[:dir]
		end

		if file_list.size == 0
			file_list = ARGV
		end
		if file_list.size == 0
			log DEBUG, 'No files, starting GUI...'
			run_gui
			exit
		end

		library = Library.new

		load_settings(library)

		# Process the library
		library.load file_list do |progress|
			puts _("%s%% complete") % (progress * 100.0)
		end

		library.find_soundtracks do |curname|
			io.agree _("'%s' may be a soundtrack or compilation. Is it? (Y/n) ") % curname
		end

		list = library.create_action_list(results[:target], 
						  results[:musicformat], 
						  results[:sndtrkformat]) do |tag, invalid, *defparm|
			io.say _("The tag '%s' has invalid characters; '%s' are not allowed") % [tag, invalid]
			io.ask _("Please type a replacement or hit enter to replace with\n%s\n" % defparm)
		end

		# Execute the list
		log INFO, _("Executing request...");
		do_it_class = ExecuteList; do_it_class = ShellScriptList if results[:script] != ''
		library.execute_action_list(list, 
					    results[:action], 
					    (results[:script].empty?) ? ExecuteList : ShellScriptList,
					    results[:script])

		# Save out the settings
		save_settings(library)
		log DEBUG, 'Exiting application'
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

exit 0 unless __FILE__ == $0

$the_app = Estelle.instance
$the_app.run
