$:.unshift File.join(File.dirname(__FILE__))

require 'spechelper'

with_steps_for :main do 
	run File.expand_path(__FILE__).gsub('.rb', '.story')
end
