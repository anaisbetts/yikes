$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/main'

describe Yikes do
	it "should display help options" do
		output = `ruby #{TestDir}/../lib/main.rb --help`

		# This test is stupid, but is a smoke test
		output.index("Usage:").should == 0
		output.index("options:").should >= 0
		output.index("library").should >= 0
		output.index("target").should >= 0
	end
end
