require 'pathname'

TestDir = File.dirname(__FILE__)

require File.join(TestDir, '..', 'lib', 'config') unless defined? $CONFIG_INCLUDED and $CONFIG_INCLUDED

path_add TestDir
path_add File.join(TestDir, '..')
path_add File.join(TestDir, '..', 'lib')
