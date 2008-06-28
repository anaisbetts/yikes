$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/main'
require 'stringio'


def hook_stdio(in_str = "")
	# Hook stdio for the call
	in_p, out_p, err_p = [$stdin, $stdout, $stderr]
	in_s, out_s, err_s = [StringIO.new(in_str, 'r'), StringIO.new('', 'w'), StringIO.new('', 'w')]
	$stdin, $stdout, $stderr = [in_s, out_s, err_s]

	begin	
		yield
	ensure
		$stdin, $stdout, $stderr = [in_p, out_p, err_p]
	end
	return [in_s, out_s, err_s]
end

describe "Test Helpers" do 
	it "should hook stdio properly" do
		i,o,e = hook_stdio do
			puts "Foo!"
		end
		o.string.should == "Foo!\n"

		i,o,e = hook_stdio("Bar\n") do
			gets().should == "Bar\n"
		end
	end
end

describe Yikes do
	it "should run properly without crashing" do
		output = `ruby #{TestDir}/../lib/main.rb --help`

		# This test is stupid, but is a smoke test
		output.index("Usage:").should == 0
	end

	it "should include the engine manager" do
		Yikes.instance.respond_to?(:load_state).should == true
	end

	it "should display help options" do
		i,o,e = hook_stdio do
			Yikes.instance.run(%w{--help})
		end

		o.string.index("options:").should >= 0
		o.string.index("library").should >= 0
		o.string.index("target").should >= 0
	end
end
