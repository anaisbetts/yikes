$:.unshift File.dirname(__FILE__)

require 'helper'
require 'lib/engine'

describe Engine do
	# TODO: Hint, we should probably test this
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
		#opn.delete
	end

	it "should build an FFMpeg command line" do
		input = "foo"; output = 'bar'
		ret = @fft.get_command(input, output)

		# FIXME: This test sucks
		ret.include?(input).should == true
		ret.include?(output).should == true
		ret.include?("ffmpeg").should == true
	end
end
