require 'rubygems'
require 'spec/story'

StoryDir = File.dirname(__FILE__)

require File.join(StoryDir, '..', 'lib', 'config') unless defined? $CONFIG_INCLUDED and $CONFIG_INCLUDED

# won't have to do this once plain_text_story_runner is moved into the library
# require File.join(File.dirname(__FILE__), "plain_text_story_runner")

path_add StoryDir
path_add File.join(StoryDir, '..', 'lib')

Dir[File.join(File.dirname(__FILE__), "steps/*.rb")].each do |file|
  require file
end
