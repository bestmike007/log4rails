require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "creates formatters" do
    expect{Log4r::Formatter.new.format(3)}.not_to raise_error 
    expect{Log4r::DefaultFormatter.new}.not_to raise_error
    expect(Log4r::DefaultFormatter.new).to be_a_kind_of Log4r::Formatter
  end
  
  it "formats with simple formatter" do
    sf = Log4r::SimpleFormatter.new
    f = Log4r::Logger.new('simple formatter')
    event = Log4r::LogEvent.new(0, f, nil, "some data")
    expect(sf.format(event)).to match(/simple formatter/)
  end
  
  it "works with basic formatter" do
    b = Log4r::BasicFormatter.new
    f = Log4r::Logger.new('fake formatter')
    event = Log4r::LogEvent.new(0, f, caller, "fake formatter")
    event2 = Log4r::LogEvent.new(0, f, nil, "fake formatter")
    # this checks for tracing
    expect(b.format(event)).to match(/in/)
    expect(b.format(event2)).not_to match(/in/)
    
    e = ArgumentError.new("argerror")
    e.set_backtrace ['backtrace']
    event3 = Log4r::LogEvent.new(0, f, nil, e)
    expect(b.format(event3)).to match(/ArgumentError/)
    expect(b.format(Log4r::LogEvent.new(0,f,nil,[1,2,3]))).to match(/Array/)
  end
  
  it "tests ObjectFormatter" do
    formatter = Log4r::ObjectFormatter.new
    expect(formatter.format Log4r::LogEvent.new(Log4r::DEBUG, Log4r::Logger.new("irb"), nil, "bestmike007")).to eq "irb>\nbestmike007\n"
  end
  
end
