require 'rubygems'
require 'spec/story'

SpecDir = File.dirname(__FILE__)

require File.join(SpecDir, '..', 'lib', 'config') unless defined? $CONFIG_INCLUDED and $CONFIG_INCLUDED

# won't have to do this once plain_text_story_runner is moved into the library
# require File.join(File.dirname(__FILE__), "plain_text_story_runner")

path_add SpecDir
path_add File.join(SpecDir, '..', 'lib')

Dir[File.join(File.dirname(__FILE__), "steps/*.rb")].each do |file|
  require file
end
