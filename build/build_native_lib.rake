require 'pathname'

def autoconf_task(name, deps = [], config_flags = [], build_commands = ["make", "make install"], clean_commands = ["make distclean"])
	library_dir = File.join(RootDir, 'ext', name)

	desc "Build the #{name} library"
	task name.to_sym => deps do |t|
		if Pathname.new(File.join(library_dir, 'bootstrap')).exist?
			sh "cd #{library_dir} && ./bootstrap"
		end

		prefix_flag = "--prefix=#{File.join(RootDir, 'lib', 'libexec')}"
		sh "cd #{library_dir} && ./configure #{prefix_flag} #{config_flags.join(' ')}"
		build_commands.each {|x| sh "cd #{library_dir} && #{x}"}
	end

	task :clean do |t|
		clean_commands.each {|x| sh "cd #{library_dir} && #{x}"}
	end
end
