require 'erb'

def expand_include(input_path, output_path)
	input = File.open(input_path, 'r')
	output = File.open(output_path, 'w')

	until input.eof? 
		buf = (line = input.readline).clone
		unless (m = /@(.*?)@/.match(line))
			output.puts buf
			next
		end

		m[1..50].each do |x|
			buf.sub!("@#{x}@", eval(x)) rescue nil
		end
		output.puts buf
	end

	[input,output].each {|x| x.close}
end

def expand_erb(input_path, output_path)
	erb = ERB.new(File.read(input_path))
	File.open(output_path, 'w') {|x| x.puts erb.result}
end
