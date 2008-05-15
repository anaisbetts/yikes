class Welcome < Application

	def index
		render
	end

	def quit 
		$do_quit = true
		render
	end
end
