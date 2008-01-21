steps_for(:main) do 
	Given("a commandline of $cmdline") do |cmdline|
		@cmdline = cmdline
	end

	When("the program is run") do 
		@output = `ruby #{File.join(File.dirname(__FILE__), '..', '..', 'lib', 'main.rb')} #{@cmdline} 2>&1`
	end

	Then("the help description should be displayed") do
		@output.should == File.read(File.join(File.dirname(__FILE__), "help_output"))
	end 
end
