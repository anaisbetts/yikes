# Code Generated by ZenTest v. 3.6.1
#                 classname: asrt / meth =  ratio%
#                 TaskQueue:    0 /    6 =   0.00%
#                      Task:    0 /    2 =   0.00%

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit' unless defined? $ZENTEST and $ZENTEST
require 'utility' 

class TestUtility < Test::Unit::TestCase
	def test_escaped_path
		assert_equal('/test/Path\ Containing\ Spaces', escaped_path("/test/Path Containing Spaces"))
	end

	def test_super_chomp
		assert_equal("chomp", super_chomp("   chomp"))
		assert_equal("chomp", super_chomp("   chomp 	"))
		assert_equal("chomp", super_chomp("chomp   		"))
	end
end
