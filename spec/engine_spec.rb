$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/engine'

EncodingItemFixture = <<EOF
--- !ruby/object:EncodingItem 
created_at: 2008-05-29 17:21:21.052007 -07:00
library: /path/to
subpath: source.avi
succeeded: false
target: /the/target

EOF

describe Engine do
	it "Should convert a file and mark it succeeded or failed" do
		source = "/path/to/source.avi"
		target = "/the/target/source.mp4"
		preview = "#{ENV["HOME"]}/.yikes/preview/01e9f4b2924dbcda2296d773017e14d1.jpg"

		# Set up our mocks
		pass_mock = flexmock("state_pass") {|f| f.should_receive(:encode_succeeded!) }
		fail_mock = flexmock("state_fail") {|f| f.should_receive(:encode_failed!) }
		flexmock(FileUtils) {|f| f.should_receive(:mkdir_p).and_return "" }

		transcoder_mock = flexmock("transcoder")
		transcoder_mock.should_receive(:transcode).with(source, target).and_return(true, false)
		transcoder_mock.should_receive(:get_screenshot).with(source, preview).times(1).and_return(true)
		tc_class = flexmock("transcoder_class")
		tc_class.should_receive(:new).and_return(transcoder_mock)

		# Try it twice, once passed and once failed
		eng = Engine.new(tc_class)
		eng.convert_file(YAML::load(EncodingItemFixture), pass_mock)
		eng.convert_file(YAML::load(EncodingItemFixture), fail_mock)
	end

end

describe FFMpegTranscoder do
	before do
		@fft = FFMpegTranscoder.new
	end

	it "should succeed a basic transcode" do
		input = File.join(TestDir, 'test_files', 'MH_egyptian_pan_L2R.avi')
		output = File.join(TestDir, 'tmp.avi')
		@fft.transcode(input, output)

		# Let's see if the file exists
		opn = Pathname.new(output)
		opn.exist?().should == true
		opn.delete
	end

	it "should build an FFMpeg command line" do
		input = "foo"; output = 'bar'
		ret = @fft.get_transcode_command(input, output)

		# FIXME: This test sucks
		ret.include?(input).should == true
		ret.include?(output).should == true
		ret.include?("ffmpeg").should == true
	end
end
