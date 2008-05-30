require 'pathname'

TestDir = Pathname.new(File.dirname(__FILE__)).realpath.to_s

require File.join(TestDir, '..', 'lib', 'config') unless defined? $CONFIG_INCLUDED and $CONFIG_INCLUDED

path_add TestDir
path_add File.join(TestDir, '..')
path_add File.join(TestDir, '..', 'lib')

Spec::Runner.configure do |config|
	config.mock_with :flexmock
end
