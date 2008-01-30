$:.unshift File.join(File.dirname(__FILE__))

require 'storyhelper'

with_steps_for :main do 
	run File.expand_path(__FILE__).gsub('_story.rb', '.story')
end
