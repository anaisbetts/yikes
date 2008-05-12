$:.unshift File.dirname(__FILE__)
Gem.path.unshift(File.join(File.dirname(__FILE__), "web", "gems"))

require 'rubygems'
require 'rake/gempackagetask' 
require 'rake/contrib/rubyforgepublisher' 
require 'rake/clean'
require 'rake/rdoctask' 
require 'rake/testtask'
require 'spec/rake/spectask'
require 'pallet'

# Merb Includes
require 'fileutils'
require 'merb-core'
require 'rubigen'
include FileUtils


# Load other build files
Dir.glob("build/*.rake").each {|x| load x}


### Constants

PKG_NAME = "yikes"
PKG_VERSION   = "0.1"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RootDir = File.dirname(__FILE__)
InstallPrefix = get_install_prefix()


########################
## Native library tasks
########################

# libgpac
GPacConfigureFlags = [ "--disable-ipv6", "--disable-wx", "--disable-ssl", "--disable-opengl" ]
#file "libexec/lib/#{libname('libgpac')}" => Dir.glob("ext/gpac/**/*.{c,h,cpp}") do |t|
autoconf_task("gpac", [], GPacConfigureFlags, ["make lib", "make install-lib"], ["make clean"])

# libx264
X264ConfigureFlags = [ 
	'--enable-mp4-output', '--enable-pthread',
	"--extra-cflags=\"-I#{File.join(RootDir, 'libexec', 'include')}\"",
	"--extra-ldflags=\"-L#{File.join(RootDir, 'libexec', 'lib')}\""
]
autoconf_task("x264", ["gpac"], X264ConfigureFlags)

# libmp4v2
autoconf_task("mp4v2")

# libfaac
FaacConfigureFlags = [ '--with-mp4v2=yes' ]
autoconf_task("faac", ["mp4v2"], FaacConfigureFlags)

# ffmpeg
FFMpegConfigureFlags = [
	"--prefix=#{RootDir}/libexec",
	'--enable-gpl', '--enable-pp', '--enable-swscaler',
	'--enable-libx264', '--enable-libfaac', '--enable-pthreads', 

	# FIXME: I get weird compile errors on OS X unless I disable MMX
	'--disable-ffserver', '--disable-ffplay', '--disable-strip', "--disable-mmx", 
	"--extra-cflags=\"-I#{File.join(RootDir, 'libexec', 'include')}\"",
	"--extra-ldflags=\"-L#{File.join(RootDir, 'libexec', 'lib')} -lpthread\""
]
autoconf_task("ffmpeg", ["x264", "faac"], FFMpegConfigureFlags)

desc "Process .erb files"
task :expandify do |f|
	Dir.glob("{lib,bin,build}/**/*.erb").each() do |ex|
		expand_erb(ex, ex.gsub(/\.erb$/, ''))
	end
end


########################
## Test Tasks
########################

desc "Update missing tests"
task :buildtests do |t|
	Dir.glob("{lib}/**/*.rb").each {|x| sh "./build_unit_test #{x}"}
end

desc "Run unit tests"
Rake::TestTask.new("test") do |t|
	t.pattern = '{test}/*.rb'
	t.verbose = true
	t.warning = true
end

desc "Run Heckle on tests"
task :heckle do |t|
	# Collect a list of defined classes 
	class_list = []
	Dir.glob('lib/**/*.rb').each do |path| 
		File.open(path) do |f| 
			class_list += f.readlines.grep(/^class /) {|x| x.gsub(/class ([a-zA-Z]*).*$/, '\1') }
			class_list.delete_if {|x| x =~ /^\W*$/}
		end
	end

	class_list.each do |x|
		STDERR.puts "Heckling #{x}"
		system("heckle -f #{x}")
	end

#	sh "echo cat " + Dir.glob("lib/**/*.rb").join(' ') + " | grep '^class ' | grep -v 'class <<' | sed -e 's/\\1/g' | xargs -I {} heckle -f"
end

desc "Run code coverage"
task :coverage do |t|
	sh "rcov -xrefs " + Dir.glob("test/**/*.rb").join(' ') + " 2>&1 >/dev/null"
end

desc "Flog code"
task :flog do |t|
	sh "flog " + Dir.glob("lib/**/*.rb").join(' ') + " | grep '^\\w'"
end 

task :alltest => [
	:test,
	:coverage,
	:heckle
]

desc "Build Documentation"
task :doc do |t|
end


#######################
## Package building
#######################

Pallet.new('yikes', "0.1") do |p|
	p.author  = 'Paul Betts'
	p.email   = 'paul.betts@gmail.com'
	p.summary = 'An automatic way to put your TV shows on your iPod'
	p.description = <<-DESC.margin
	  |This is a description!
	DESC

	p.packages << Pallet::Gem.new(p) do |gem|
		gem.depends = ['rake']
		gem.files.include FileList['bin/*']
		gem.files.include FileList['share/**/*']
		gem.files.include FileList['lib/**/*']
	end

#	load_os("pallet_deb")
end

desc "Create a bundle folder that has all dependencies included"
task :bundle do
	ENV["REQUIRE2LIB_LIBDIR"] = "#{RootDir}/bundle"
	sh "#{RootDir}/findlibs/main.rb #{RootDir}/lib/main.rb"
end


#######################
## Gettext section
#######################

require 'gettext/utils'

desc "Create mo-files for l10n"
task :makemo do 
	GetText.create_mofiles(true, "./po", "./data/locale")
end

desc "Update pot/po files to match new version." 
task :updatepo do
	GetText.update_pofiles(PKG_NAME,
			       Dir.glob("{app,lib}/**/*.{rb,rhtml}"),
			       "#{PKG_NAME} #{PKG_VERSION}")
end

#######################
## Merb Tasks
#######################

# Load the basic runtime dependencies; this will include 
# any plugins and therefore plugin rake tasks.
init_env = ENV['MERB_ENV'] || 'rake'
Merb.load_dependencies(:environment => init_env)
     
# Get Merb plugins and dependencies
Merb::Plugins.rakefiles.each { |r| require r } 

desc "start runner environment"
task :merb_env do
  Merb.start_environment(:environment => init_env, :adapter => 'runner')
end

class Freezer
  
  class << self

    def components
      {
        "core" => "git://github.com/wycats/merb-core.git",
        "more" => "git://github.com/wycats/merb-more.git",
        "plugins" => "git://github.com/wycats/merb-plugins.git"
      }
    end

    def framework_dir
      # Should allow customization of this directory's location?
      File.join(File.dirname(__FILE__), "framework")
    end

    def gitmodules
      File.join(File.dirname(__FILE__), ".gitmodules")    
    end

    def freeze(component, update = false)
      new(component, update).freeze
    end

  end

  def initialize(component, update)
    @component = "merb-" + component
    @update    = update
  end
  
  def freeze
    # Ensure that required git commands are available
    %w(git-pull git-submodule).each do |bin|
      next if in_path?(bin)
      $stderr.puts "ERROR: #{bin} must be avaible in PATH"
      exit 1
    end

    unless File.directory?(framework_dir)
      puts "Creating framework directory ..."
      FileUtils.mkdir_p(framework_dir)
    end

    if managed?
      puts "#{@component} seems to be already managed by git-submodule."
      if @update
        puts "Trying to update #{@component} ..."
        sh "cd #{framework_dir}/#{@component} && git-pull"
      end
    else
      puts "Creating submodule for #{@component} ..."
      sh "git-submodule --quiet add #{components[@component.gsub("merb-", '')]} #{File.basename(framework_dir)}/#{@component}" 
      if $?.success?
        sh("git-submodule init")
      else
        # Should this instead be a raise?
        $stderr.puts("ERROR: unable to create submodule for #{@component}")
      end
    end
  end

  protected

  def in_submodule?
    return false unless File.exists?(gitmodules)
    File.read(gitmodules) =~ %r![submodule "#{framework_dir}/#{@component}"]!
  end

  def managed?
    File.directory?(File.join(framework_dir, @component)) || in_submodule?
  end

  def in_path?(bin)
    `which #{bin}`
    !$?.nil? && $?.success?
  end

end

task :freeze => Freezer.components.keys.map { |component| "freeze:#{component}" }
namespace :freeze do
  Freezer.components.each do |component, git_repository|
    desc "Freeze #{component} from #{git_repository}"
    task component do
      Freezer.freeze(component, ENV["UPDATE"])
    end
  end
end


#######################
## Final tasks
#######################

desc "Miscellaneous post-build tasks"
task :postbuild => [:expandify] do 
	# FIXME: There's a Rake'y way to do this...
	sh "cp #{RootDir}/build/config.rb #{RootDir}/lib" 
	sh "mkdir -p #{RootDir}/bin && mv #{RootDir}/build/execscript #{RootDir}/bin/yikes"
	sh "chmod +x #{RootDir}/bin/yikes"
end

# Default Actions
task :default => [
	:updatepo,
	:makemo,
	:expandify,
	:postbuild,
]


