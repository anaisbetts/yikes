require 'pathname'

def build_native_lib(name, config_flags = [], build_commands = ["make", "make install"])
	library_dir = File.join(RootDir, 'ext', name)
	if Pathname.new(File.join(library_dir, 'bootstrap')).exist?
		sh "cd #{library_dir} && ./bootstrap"
	end

	prefix_flag = "--prefix=#{File.join(RootDir, 'obj')}"
	sh "cd #{library_dir} && ./configure #{prefix_flag} #{config_flags.join(' ')}"
	build_commands.each {|x| sh "cd #{library_dir} && #{x}"}

	#Dir.glob(File.join(RootDir, "{obj,ext}", "**", "*.{dll,so,dylib}")).each {|x| sh "cp #{x} #{File.join(RootDir, 'bin')}" }
end
