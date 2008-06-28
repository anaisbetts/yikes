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
		transcoder_mock.should_receive(:before_transcode)
		tc_class = flexmock("transcoder_class")
		tc_class.should_receive(:new).and_return(transcoder_mock)

		# Try it twice, once passed and once failed
		eng = Engine.new(tc_class)
		eng.convert_file(YAML::load(EncodingItemFixture), pass_mock)
		eng.convert_file(YAML::load(EncodingItemFixture), fail_mock)
	end

end

class MockEngineManager
	include EngineManager
end

describe EngineManager do
	it "should be able to add engines given a source and target" do
		em = MockEngineManager.new
		source = "/path/to/source.avi"
		target = "/the/target/source.mp4"
		em.add_engine(source, target)
		em.active_engines.length.should == 1
	end

	it "should be able to remove engines" do
		em = MockEngineManager.new
		source = "/path/to/source.avi"
		target = "/the/target/source.mp4"

		em.add_engine(source, target)
		em.active_engines.length.should == 1

		em.remove_engine(source, target)
		em.active_engines.length.should == 0
	end

	it "should save and load state properly" do
		em = MockEngineManager.new
		s = em.load_state("/doesnt/___exist")
		items = [1,2,3,4,5].collect {|x| EncodingItem.new(Library, "bob/foo_#{x}.avi", Target) }

		source = "/path/to/source.avi"
		target = "/the/target/source.mp4"
		s = em.add_engine(source, target).state
		
		s.add_to_queue(items)
		two_items = s.dequeue_items(2)
		s.encode_failed! two_items[0]
		s.encode_succeeded! two_items[1]

		p = Pathname.new(File.join(TestDir, "state.yaml"))
		p.delete if p.exist?
		em.save_state(p.to_s)

		em = MockEngineManager.new
		em.load_state(p.to_s)
		em.active_engines.length.should == 1
		s = em.active_engines[0].state

		s.items_count.should == 3
		s.get_finished_items.length.should == 2
		s.get_finished_items[1].source_path.should == "/path/to/library/bob/foo_2.avi"
		
		p.delete
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
