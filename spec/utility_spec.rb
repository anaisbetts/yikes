$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/utility'

describe "utility functions" do
	it "should escape paths" do
		escaped_path("/test/Path Containing Spaces").should == '/test/Path\ Containing\ Spaces'
	end

	it "should be able to Super Chomp!" do
		super_chomp("   chomp").should == "chomp"
		super_chomp("   chomp 	").should == "chomp"
		super_chomp("chomp   		").should == "chomp"
	end

	it "should be able to verify if a path is file'ish" do
		filelike?(__FILE__).should == true
		filelike?(TestDir).should == false
		filelike?("./foobar").should == false
	end
end
