$:.unshift File.dirname(__FILE__)

require 'rubygems'                                                                                                                             
require 'rake/gempackagetask'                                                                                                                  
require 'rake/contrib/rubyforgepublisher'                                                                                                      
require 'rake/clean'
require 'rake/rdoctask'                                                                                                                        
require 'rake/testtask'
#require 'spec'

# Load other build files
Dir.glob("build/*.rake").each {|x| load x}

### Constants

PKG_NAME = "yikes"
PKG_VERSION   = "0.1"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

# Fixed up clean section to pick up extensions
CLEAN = FileList["**/*~", "**/*.bak", "**/core", 'ext/taglib/**/*.o', 'ext/**/*.dll', 'ext/**/*.so', 'ext/**/*.dylib', 'bin/*', 'obj/*']
CLOBBER = FileList['ext/**/CMakeCache.txt']

RootDir = File.dirname(__FILE__)


########################
## Tasks
########################

desc "Process .erb files"
task :expandify do |f|
	Dir.glob("{lib,bin}/**/*.erb").each() do |ex|
		expand_erb(ex, ex.gsub(/\.erb$/, ''))
	end
end

# libgpac
GPacConfigureFlags = [ "--disable-ipv6", "--disable-wx", "--disable-ssl", "--disable-opengl" ]
desc "Build the libgpac library"
task :gpac do |t|
	build_native_lib("gpac", GPacConfigureFlags, ["make lib", "make install-lib"])
end

# libx264
X264ConfigureFlags = [
	'--enable-mp4-output', "--enable-pic",  #'--enable-pthread',
	"--extra-cflags=\"-I#{File.join(RootDir, 'obj', 'include')}\"",
	"--extra-ldflags=\"-L#{File.join(RootDir, 'obj', 'lib')}\""
]
desc "Build the libx264 library"
task :x264 do |t|
	build_native_lib("x264", X264ConfigureFlags)
end

# libfaac
desc "Build the faac library"
task :faac do |t|
	build_native_lib("faac")
end

# ffmpeg
FFMpegConfigureFlags = [
	"--prefix=#{RootDir}/obj",
	'--enable-gpl', '--enable-pp', '--enable-swscaler',
	'--enable-libx264', '--enable-libfaac', #'--enable-pthreads',

	# FIXME: I get weird compile errors on OS X unless I disable MMX
	'--disable-ffserver', '--disable-ffplay', '--disable-strip', "--disable-mmx",
	"--extra-cflags=\"-I#{File.join(RootDir, 'obj', 'include')}\"",
	"--extra-ldflags=\"-L#{File.join(RootDir, 'obj', 'lib')} -lpthread\""
]
desc "Build the ffmpeg library"
task :ffmpeg do |t|
	build_native_lib("ffmpeg", FFMpegConfigureFlags)
end

# Taglib
desc "Build the Taglib library"
task :taglib do |t|
	sh "cd ext/taglib && cmake ."
	sh "cd ext/taglib && make"
	sh "mkdir -p bin"
	Dir.glob("ext/**/*.{dll,so,dylib}").each {|x| sh "cp #{x} bin/"}
end

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

# Default Action
task :default => [
#	:taglib,
	:updatepo,
	:makemo,
	:expandify,
]

task :alltest => [
	:test,
	:coverage,
	:heckle
]


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
