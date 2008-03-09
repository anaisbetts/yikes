# Copyright Erik Veenstra <rubyscript2exe@erikveen.dds.nl>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307 USA.

require "ev/ftools"
require "rbconfig"

exit	if __FILE__ == $0

module REQUIRE2LIB
  JUSTRUBYLIB	= ARGV.include?("--require2lib-justrubylib")
  JUSTSITELIB	= ARGV.include?("--require2lib-justsitelib")
  RUBYGEMS	= (not JUSTRUBYLIB)
  VERBOSE	= ARGV.include?("--require2lib-verbose")
  QUIET		= (ARGV.include?("--require2lib-quiet") and not VERBOSE)
  LOADED	= []

  ARGV.delete_if{|arg| arg =~ /^--require2lib-/}

  ORGDIR	= Dir.pwd
  THISFILE	= File.expand_path(__FILE__)
  LIBDIR	= File.expand_path((ENV["REQUIRE2LIB_LIBDIR"] or "./test"))
  LOADSCRIPT	= File.expand_path((ENV["REQUIRE2LIB_LOADSCRIPT"] or "."))
  RUBYLIBDIR	= Config::CONFIG["rubylibdir"]
  SITELIBDIR	= Config::CONFIG["sitelibdir"]

  at_exit do
    Dir.chdir(ORGDIR)

    REQUIRE2LIB.gatherlibs
  end

  def self.gatherlibs
    $stderr.puts "Gathering files..."	unless QUIET

    File.makedirs(LIBDIR)

    if RUBYGEMS
      begin
        Gem.dir
        rubygems	= true
      rescue NameError
        rubygems	= false
      end
    else
      rubygems		= false
    end

    pureruby	= true

    if rubygems
      require "fileutils"	# Hack ???

      requireablefiles	= []

      Dir.mkdir(File.expand_path("local.gems", LIBDIR))
      Dir.mkdir(File.expand_path("local.gems/gems", LIBDIR))
      Dir.mkdir(File.expand_path("local.gems/specifications", LIBDIR))

      Gem::Specification.list.each do |gem|
        if gem.loaded?
          $stderr.puts "Found gem #{gem.name} (#{gem.version})."	if VERBOSE

          fromdir	= File.join(gem.installation_path, "specifications")
          todir		= File.expand_path("local.gems/specifications", LIBDIR)

          fromfile	= File.join(fromdir, "#{gem.full_name}.gemspec")
          tofile	= File.join(todir, "#{gem.full_name}.gemspec")

          File.copy(fromfile, tofile)

          fromdir	= gem.full_gem_path
          todir		= File.expand_path(File.join("local.gems/gems", gem.full_name), LIBDIR)

          Dir.copy(fromdir, todir)

          Dir.find(todir).each do |file|
            if File.file?(file)
              gem.require_paths.each do |lib|
                unless lib.empty?
                  lib	= File.expand_path(lib, todir)
                  lib	= lib + "/"

                  requireablefiles << file[lib.length..-1]	if file =~ /^#{lib}/
                end
              end
            end
          end
        end
      end
    end

    ($" + LOADED).each do |req|
      catch :found do
        $:.each do |lib|
          fromfile	= File.expand_path(req, lib) 
          tofile	= File.expand_path(req, LIBDIR) 

          if File.file?(fromfile)
            unless fromfile == tofile or fromfile == THISFILE
              unless (rubygems and requireablefiles.include?(req))	# ??? requireablefiles might be a little dangerous.
                if (not JUSTRUBYLIB and not JUSTSITELIB) or
                   (JUSTRUBYLIB and fromfile.include?(RUBYLIBDIR)) or
                   (JUSTSITELIB and fromfile.include?(SITELIBDIR))
                  $stderr.puts "Found #{fromfile} ."		if VERBOSE

                  File.makedirs(File.dirname(tofile))	unless File.directory?(File.dirname(tofile))
                  File.copy(fromfile, tofile)

                  pureruby	= false	unless req =~ /\.(rbw?|ruby)$/i
                else
                  $stderr.puts "Skipped #{fromfile} ."	if VERBOSE
                end
              end
            end

            throw :found
          end
        end

        #$stderr.puts "Can't find #{req} ."	unless req =~ /^ev\// or QUIET
        #$stderr.puts "Can't find #{req} ."	unless req =~ /^(\w:)?[\/\\]/ or QUIET
      end
    end

    $stderr.puts "Not all required files are pure Ruby."	unless pureruby	if VERBOSE

    unless LOADSCRIPT == ORGDIR
      File.open(LOADSCRIPT, "w") do |f|
        f.puts "module RUBYSCRIPT2EXE"
        f.puts "  REQUIRE2LIB_FROM_APP={}"

        RUBYSCRIPT2EXE.class_variables.each do |const|
          const	= const[2..-1]

          f.puts "  REQUIRE2LIB_FROM_APP[:#{const}]=#{RUBYSCRIPT2EXE.send(const).inspect}"
        end

        f.puts "  REQUIRE2LIB_FROM_APP[:rubygems]=#{rubygems.inspect}"
        f.puts "end"
      end
    end
  end
end

module Kernel
  alias :require2lib_require :require
  alias :require2lib_load :load
  def load(filename, wrap=false)
    REQUIRE2LIB::LOADED << filename	unless REQUIRE2LIB::LOADED.include?(filename)

    require2lib_load(filename, wrap)
  end
end
