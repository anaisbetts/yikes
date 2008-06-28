$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/state'

class MockState
	include ApplicationState
end

Library = "/path/to/library"
Target = "/the/target"
describe ApplicationState::State do
	it "should act like a queue" do
		s = ApplicationState::State.new(Library)
		items = [1,2,3,4,5].collect {|x| EncodingItem.new(Library, "bob/foo_#{x}.avi", Target) }
		
		s.add_to_queue(items)
		s.items_count.should == 5
		s.get_finished_items.length.should == 0
		
		two_items = s.dequeue_items(2)
		two_items.length.should == 2
		two_items[0].target_path.should == "/the/target/bob/foo_1.mp4"
		s.items_count.should == 3

		s.encode_succeeded! two_items[1]
		s.get_finished_items.length.should == 1
		s.get_finished_items[0].source_path.should == "/path/to/library/bob/foo_2.avi"
	end
end

describe EncodingItem do
	it "should be able to extract subpaths" do
		EncodingItem.extract_subpath("/source/path", "/source/path/to/target_1.avi").should == "to/target_1.avi"
		EncodingItem.extract_subpath("", "/source/path/to/target_2.avi").should == "/source/path/to/target_2.avi"
	end

	it "should be able to build paths" do
		EncodingItem.build_target_path("/target/dir", "path/test.avi").should == "/target/dir/path/test.mp4"
	end
end
