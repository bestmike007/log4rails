require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "tests that MDC works on multple threads" do
    Log4r::MDC.put("user","bestmike007")
    t = Thread.new("test first copy") do |name|
      expect(Log4r::MDC.get("user")).to eq "bestmike007"
      Log4r::MDC.put("user", "unique")
      expect(Log4r::MDC.get("user")).to eq "unique"
    end
    t.join
    expect(Log4r::MDC.get("user")).to eq "bestmike007"
  end
  
  it "tests MDC output" do
    Log4r::MDC.put(:user, "symbol")
    Log4r::MDC.put("string", "string")
    Log4r::MDC.put(5, "number")
    l = Log4r::Logger.new 'test'
    o = Log4r::FileOutputter.new('test', 'filename'=>'/tmp/log4rails-test.log', :trunc=>true)
    l.add o
    expect {
      f = Log4r::PatternFormatter.new :pattern=> "%l user: %X{:user} %X{strng} %X{5}"
      Log4r::Outputter['test'].formatter = f
      l.debug "And this?"
      l.info "How's this?"
      l.error "and a really freaking huge line which we hope will be trimmed?"
      e = ArgumentError.new("something barfed")
      e.set_backtrace Array.new(5, "trace junk at thisfile.rb 154")
      l.fatal e
      l.info [1, 3, 5]
    }.not_to raise_error
  end
  
end
