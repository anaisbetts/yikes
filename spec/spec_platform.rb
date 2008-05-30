$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/platform'

describe Platform do
	it "should find our bindir" do
		Platform.binary_dir.should == (AppConfig::RootDir + "/bin")
	end

	it "should find home dir" do
		Platform.home_dir.should == "#{ENV['HOME']}"
	end

	it "should identify the OS" do
		# TODO: This test is blatantly retarded
		Platform.os.should == :osx
	end

	it "should find external commands" do
		Platform.which("ls").should == `which ls`
	end
end
