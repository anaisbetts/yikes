def expand_file(input_path, output_path)
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
