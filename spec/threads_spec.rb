require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "tests multiple threads" do
    expect {
      (0..100).map do |i|
        Thread.new do
          Thread.current[:logger] = Log4r::Logger.new "Hello #{i}"
          Thread.current[:logger].outputters = [Log4r::StdoutOutputter.new("log4r#{i}")]
          Thread.current[:logger].outputters.each { |j| j.flush }
          Thread.current.exit()
        end
      end.each do |thr| thr.join end
    }.not_to raise_error
  end
  
end
