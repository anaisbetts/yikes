$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/state'

describe EncodingItem do
	it "should be able to extract subpaths" do
		EncodingItem.extract_subpath("/source/path", "/source/path/to/target_1.avi").should == "to/target_1.avi"
		EncodingItem.extract_subpath("", "/source/path/to/target_2.avi").should == "/source/path/to/target_2.avi"
	end

	it "should be able to build paths" do
		EncodingItem.build_target_path("/target/dir", "path/test.avi").should == "/target/dir/path/test.mp4"
	end
end
