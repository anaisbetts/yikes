This is the main user scenario for Yikes

Story: main usage
	Scenario: get help
		Given a commandline of '--help'

		When the program is run

		Then the help description should be displayed
