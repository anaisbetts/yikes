require 'feed_tools'

class Podcast < Application
	def index
		app = Yikes.instance

		feed = FeedTools::Feed.new
		feed.title = "Yikes Video Feed of #{app.state.library}"
		feed.author.name = "Yikes"
		feed.link = "http://github.com/xpaulbettsx/yikes"

		app.state.get_finished_items.each do |item|
			f = FeedTools::FeedItem.new

			f.title = "#{Pathname.new(item.path).basename}"
			f.link = "http://foobar.com"
			f.content = "I am a test"

			feed.entries << f
		end

		render feed.build_xml("rss", 2.0), :layout => false
	end
end
