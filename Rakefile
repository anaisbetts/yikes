$:.unshift File.dirname(__FILE__)

require 'rubygems'                                                                                                                             
require 'rake/gempackagetask'                                                                                                                  
require 'rake/contrib/rubyforgepublisher'                                                                                                      
require 'rake/clean'
require 'rake/rdoctask'                                                                                                                        
require 'rake/testtask'
require 'pallet'
#require 'spec'

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
desc "Build the libgpac library"
#file "libexec/lib/#{libname('libgpac')}" => Dir.glob("ext/gpac/**/*.{c,h,cpp}") do |t|
task :gpac do |t|
	build_native_lib("gpac", GPacConfigureFlags, ["make lib", "make install-lib"])
end

# libx264
X264ConfigureFlags = [ 
	'--enable-mp4-output', '--enable-pthread',
	"--extra-cflags=\"-I#{File.join(RootDir, 'libexec', 'include')}\"",
	"--extra-ldflags=\"-L#{File.join(RootDir, 'libexec', 'lib')}\""
]
desc "Build the libx264 library"
task :x264 => [:gpac] do |t|
	build_native_lib("x264", X264ConfigureFlags)
end

# libmp4v2
desc "Build the mp4v2 library"
task :mp4v2 do |t|
	build_native_lib("mp4v2")
end

# libfaac
FaacConfigureFlags = [ '--with-mp4v2' ]
desc "Build the faac library"
task :faac => [:mp4v2] do |t|
	build_native_lib("faac", FaacConfigureFlags)
end

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
desc "Build the ffmpeg library"
task :ffmpeg => [:x264, :faac] do |t|
	build_native_lib("ffmpeg", FFMpegConfigureFlags)
end

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
	t.pattern = 'test/*.rb'
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
		gem.requirements = ['fakeroot', 'dpkg-dev']
		gem.files.include FileList['bin/*']
		gem.files.include FileList['share/**/*']
		gem.files.include FileList['lib/**/*']
	end

	if os() == :linux
		p.packages << Pallet::Deb.new(p) do |deb|
			deb.depends    = %w{build-essential rake}
			deb.recommends = %w{fakeroot}
			deb.copyright  = 'COPYING'
			
			deb.section    = 'utils'
			deb.files      = [ 
				Installer.new('bin', '/usr/bin'),
				Installer.new('lib', '/usr/lib/yikes'),
				Installer.new('libexec', '/usr/lib/yikes/libexec'),
			]

			deb.docs = [ 
				Installer.new('doc',       'html'),
				Installer.new('Rakefile',  'examples'),
				Installer.new { Dir['[A-Z][A-Z]*'] }, 
			]
		end
	end
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
## Final tasks
#######################

task :clean do
	puts "I'm a clean hook!"
end

desc "Miscellaneous post-build tasks"
task :postbuild => [:expandify] do 
	sh "cp #{RootDir}/build/ffmpeg_run.sh #{RootDir}/lib" 
	sh "cp #{RootDir}/build/config.rb #{RootDir}/lib" 
end

# Default Action
task :default => [
	:updatepo,
	:makemo,
	:expandify,
	:postbuild,
]
