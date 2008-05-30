class Podcast < Application
	provides :xml

	def index; render; end
end
