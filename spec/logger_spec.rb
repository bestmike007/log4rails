require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "has a singleton root logger" do
    l1 = Log4r::Logger.root
    l2 = Log4r::Logger['root']
    l3 = Log4r::Logger.global
    expect(l1).to be l2
    expect(l1).to be l3
    expect(l1.is_root?).to be true
    expect(l1.parent).to be nil
  end
  
  it "validates when creating a logger" do
    expect{ Log4r::Logger.new }.to raise_error(ArgumentError)
    expect{ Log4r::Logger.new('validate', nil) }.not_to raise_error
  end
  
  it "sets levels" do
    l = Log4r::Logger.new("create_method")
    l.level = Log4r::WARN
    expect(l.debug?).to be false
    expect(l.info?).to be false
    expect(l.warn?).to be true
    expect(l.error?).to be true
    expect(l.fatal?).to be true
    expect(l.off?).to be false
    expect(l.all?).to be false
    
    l.level = Log4r::OFF
    expect(l.off?).to be true
    expect(l.all?).to be false
    
    l.level = Log4r::ALL
    expect(l.off?).to be false
    expect(l.all?).to be true
  end
  
  it "can add outputters" do
    Log4r::StdoutOutputter.new('fake1')
    Log4r::StdoutOutputter.new('fake2')
    a = Log4r::Logger.new("add")
    expect{ a.add 'bogus' }.to raise_error(TypeError)
    expect{ a.add Class }.to raise_error(TypeError)
    expect{ a.add 'fake1', Class }.to raise_error(TypeError)
    expect{ a.add 'fake1', 'fake2' }.not_to raise_error
  end
  
  it "tests repository" do
    expect { Log4r::Logger.get('bogusbogus') }.to raise_error(NameError)
    expect { Log4r::Logger['bogusbogus'] }.not_to raise_error
  end
  
  it "tests logger hierarchy" do
    a = Log4r::Logger.new("a")
    a.additive = true
    expect(a.name ).to eq "a"
    expect(a.path ).to eq ""
    expect(a.level).to eq Log4r::Logger.root.level
    expect(a.parent).to be Log4r::Logger.root
    a.level = Log4r::WARN
    
    b = Log4r::Logger.new("a::b")
    expect(b.name).to eq "b"
    expect(b.path).to eq "a"
    expect(b.level).to eq a.level
    expect(b.parent).to be a
    
    c = Log4r::Logger.new("a::b::c")
    expect(Log4r::Logger["a::b::c"]).to be c
    expect(c.name).to eq "c"
    expect(c.path).to eq "a::b"
    expect(c.level).to eq b.level
    expect(c.parent).to be b
    
    d = Log4r::Logger.new("a::d")
    expect(Log4r::Logger["a::d"]).to be d
    expect(d.name).to eq "d"
    expect(d.path).to eq "a"
    expect(d.level).to eq a.level
    expect(d.parent).to be a
    expect{ Log4r::Logger.new("::a") }.to raise_error(ArgumentError)
  end
  
  it "tests undefined parents" do
    a = Log4r::Logger.new 'has::no::real::parents::me'
    expect(a.parent).to be Log4r::Logger.root
    b = Log4r::Logger.new 'has::no::real::parents::me::child'
    expect(b.parent).to be a
    c = Log4r::Logger.new 'has::no::real::parents::metoo'
    expect(c.parent).to be Log4r::Logger.root
    p = Log4r::Logger.new 'has::no::real::parents'
    expect(p.parent).to be Log4r::Logger.root
    expect(a.parent).to be p
    expect(b.parent).to be a
    expect(c.parent).to be p
    Log4r::Logger.each{|fullname, logger|
      if logger != a and logger != c
        expect(logger.parent).not_to be p
      end
    }
  end
  
  it "tests levels" do
    l = Log4r::Logger.new("levels", Log4r::WARN)
    l.add(Log4r::Outputter.stdout)
    expect(l.level).to eq Log4r::WARN
    expect(l.fatal?).to eq true
    expect(l.error?).to eq true
    expect(l.warn?).to eq true
    expect(l.info?).to eq false
    expect(l.debug?).to eq false
    l.debug "debug message should NOT show up"
    l.info "info message should NOT show up"
    l.warn "warn messge should show up. 3 total"
    l.error "error messge should show up. 3 total"
    l.fatal "fatal messge should show up. 3 total"
    l.level = Log4r::ERROR
    expect(l.level).to eq Log4r::ERROR
    expect(l.fatal?).to eq true
    expect(l.error?).to eq true
    expect(l.warn?).to eq false
    expect(l.info?).to eq false
    expect(l.debug?).to eq false
    l.debug "debug message should NOT show up"
    l.info "info message should NOT show up"
    l.warn "warn messge should NOT show up."
    l.error "error messge should show up. 2 total"
    l.fatal "fatal messge should show up. 2 total"
    l.level = Log4r::WARN
  end
  
  it "logs with blocks" do
    l = Log4r::Logger.new 'logblocks'
    l.level = Log4r::WARN
    l.add(Log4r::Outputter.stdout)
    expect {
      l.debug { puts "should NOT show up"; "LOGBLOCKS" }
      l.fatal { puts "should show up"; "LOGBLOCKS" }
      l.fatal { nil }
      l.fatal {}
    }.not_to raise_error
  end
  
  it "hierarchically logs" do
    expect {
      a = Log4r::Logger.new("one")
      a.add(Log4r::StdoutOutputter.new 'so1')
      b = Log4r::Logger.new("one::two")
      b.add(Log4r::StdoutOutputter.new 'so2')
      c = Log4r::Logger.new("one::two::three")
      c.add(Log4r::StdoutOutputter.new 'so3')
      d = Log4r::Logger.new("one::two::three::four")
      d.add(Log4r::StdoutOutputter.new 'so4')
      d.additive = false
      e = Log4r::Logger.new("one::two::three::four::five")
      e.add(Log4r::StdoutOutputter.new 'so5')
  
      a.fatal "statement from a should show up once"
      b.fatal "statement from b should show up twice"
      c.fatal "statement from c should show up thrice"
      d.fatal "statement from d should show up once"
      e.fatal "statement from e should show up twice"
    }.not_to raise_error
  end
  
  it "tests multiple outputters" do
    expect {
      f1 = Log4r::FileOutputter.new('f1', :filename => "/tmp/log4rails-test-1.log", :level=>Log4r::ALL)
      f2 = Log4r::FileOutputter.new('f2', :filename => "/tmp/log4rails-test-2.log", :level=>Log4r::DEBUG)
      f3 = Log4r::FileOutputter.new('f3', :filename => "/tmp/log4rails-test-3.log", :level=>Log4r::ERROR)
      f4 = Log4r::FileOutputter.new('f4', :filename => "/tmp/log4rails-test-4.log", :level=>Log4r::FATAL)

      l = Log4r::Logger.new("multi")
      l.add(f1, f3, f4)
  
      a = Log4r::Logger.new("multi::multi2")
      a.level = Log4r::ERROR
      a.add(f2, f4)
      
      l.debug "debug test_multi_outputters"
      l.info "info test_multi_outputters"
      l.warn "warn test_multi_outputters"
      l.error "error test_multi_outputters"
      l.fatal "fatal test_multi_outputters"
  
      a.debug "debug test_multi_outputters"
      a.info "info test_multi_outputters"
      a.warn "warn test_multi_outputters"
      a.error "error test_multi_outputters"
      a.fatal "fatal test_multi_outputters"
      
      f1.close; f2.close; f3.close; f4.close
    }.not_to raise_error
  end
  
  it "tests custom formatters" do
    expect {
      class MyFormatter1 < Log4r::Formatter
        def format(event)
          return "MyFormatter1\n"
        end
      end
      
      class MyFormatter2 < Log4r::Formatter
        def format(event)
          return "MyFormatter2\n"
        end
      end
      l = Log4r::Logger.new('custom_formatter')
      o = Log4r::StdoutOutputter.new('formatter'=>MyFormatter1.new)
      l.add o
      l.error "try myformatter1"
      l.fatal "try myformatter1"
      o.formatter = MyFormatter2.new
      l.error "try formatter2"
      l.fatal "try formatter2"
    }.not_to raise_error
  end
  
end
