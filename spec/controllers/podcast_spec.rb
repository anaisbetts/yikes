require File.join(File.dirname(__FILE__), "..", 'spec_helper.rb')

describe Podcast, "index action" do
  before(:each) do
    dispatch_to(Podcast, :index)
  end
end