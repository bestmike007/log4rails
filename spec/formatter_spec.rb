require_relative "rspec_helper"

include Log4r

RSpec.describe "Log4r" do
  
  it "creates formatters" do
    expect{Formatter.new.format(3)}.not_to raise_error 
    expect{DefaultFormatter.new}.not_to raise_error
    expect(DefaultFormatter.new).to be_a_kind_of Formatter
  end
  
  it "formats with simple formatter" do
    sf = SimpleFormatter.new
    f = Logger.new('simple formatter')
    event = LogEvent.new(0, f, nil, "some data")
    expect(sf.format(event)).to match(/simple formatter/)
  end
  
  it "works with basic formatter" do
    b = BasicFormatter.new
    f = Logger.new('fake formatter')
    event = LogEvent.new(0, f, caller, "fake formatter")
    event2 = LogEvent.new(0, f, nil, "fake formatter")
    # this checks for tracing
    expect(b.format(event)).to match(/in/)
    expect(b.format(event2)).not_to match(/in/)
    
    e = ArgumentError.new("argerror")
    e.set_backtrace ['backtrace']
    event3 = LogEvent.new(0, f, nil, e)
    expect(b.format(event3)).to match(/ArgumentError/)
    expect(b.format(LogEvent.new(0,f,nil,[1,2,3]))).to match(/Array/)
  end
  
end
