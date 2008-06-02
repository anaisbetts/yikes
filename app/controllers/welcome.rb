class Welcome < Application
	provides :html, :xml

	def index
		render
	end

	def quit 
		$do_quit = true
		render
	end
end
