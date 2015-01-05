require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "create std outputter automatically" do
    expect(Log4r::Outputter["stdout"]).not_to be nil
    expect(Log4r::Outputter["stderr"]).not_to be nil
    names = []
    Log4r::Outputter.each do |name, o|
      expect(o.name).to eq name
      names << name
    end
    expect(names).to eq ['stdout', 'stderr']
    Log4r::Outputter.each_outputter do |o|
      expect(o).to be_a(Log4r::Outputter)
    end
  end
  
  it 'tests validation' do
     expect{ Log4r::Outputter.new }.to raise_error(ArgumentError)
     expect{ Log4r::Outputter.new nil }.to raise_error(ArgumentError)
     expect{ Log4r::Outputter.new 'fonda', :level => -10 }.to raise_error(ArgumentError)
     expect{ Log4r::Outputter.new 'fonda', :formatter => -10 }.to raise_error(TypeError)
  end
  
  it "tests io outputters" do
    expect {
      Log4r::IOOutputter.new('foo3', $stdout)
      Log4r::IOOutputter.new('foo4', $stderr)
    }.not_to raise_error
    f = File.new("/tmp/log4rails-test.log", "w")
    o = Log4r::IOOutputter.new('asdf', f)
    o.close
    expect(f.closed?).to be true
    expect(o.level).to eq(Log4r::OFF)
    expect {
      o.close
    }.not_to raise_error
    # test repository
    expect(Log4r::Outputter['foo3']).to be_an(Log4r::IOOutputter)
    expect(Log4r::Outputter['foo4']).to be_an(Log4r::IOOutputter)
    expect(Log4r::Outputter['asdf']).to be_an(Log4r::IOOutputter)
  end
  
  it "tests validation and create" do
    expect {
      Log4r::StdoutOutputter.new('out', 'level' => Log4r::DEBUG)
      Log4r::FileOutputter.new('file', 'filename' => '/tmp/log4rails-test.log', :trunc => true)
    }.not_to raise_error
    a = Log4r::StdoutOutputter.new 'out2'
    expect(a.level).to eq(Log4r::Logger.root.level)
    expect(a.formatter).to be_a(Log4r::DefaultFormatter)
    b = Log4r::StdoutOutputter.new('ook', :level => Log4r::DEBUG, :formatter => Log4r::Formatter)
    expect(b.level).to eq(Log4r::DEBUG)
    expect(b.formatter).to be_a(Log4r::Formatter)
    c = Log4r::StdoutOutputter.new('akk', :formatter => Log4r::Formatter)
    expect(c.level).to eq(Log4r::Logger.root.level)
    expect(c.formatter).to be_a(Log4r::Formatter)
    c = Log4r::StderrOutputter.new('iikk', :level => Log4r::OFF)
    expect(c.level).to eq(Log4r::OFF)
    expect(c.formatter).to be_a(Log4r::DefaultFormatter)
    o = Log4r::StderrOutputter.new 'ik'
    expect{ o.formatter = Log4r::DefaultFormatter }.not_to raise_error
    expect(o.formatter).to be_a(Log4r::DefaultFormatter)
  end
  
  it 'tests boundaries' do
    o = Log4r::StderrOutputter.new('ak', :formatter => Log4r::Formatter)
    expect{ o.formatter = nil }.to raise_error(TypeError)
    expect{ o.formatter = String }.to raise_error(TypeError)
    expect{ o.formatter = "bogus" }.to raise_error(TypeError)
    expect{ o.formatter = -3 }.to raise_error(TypeError)
    # the formatter should be preserved
    expect(o.formatter).to be_a(Log4r::Formatter)
  end
  
  it "tests file logger" do
    expect{ Log4r::FileOutputter.new 'f' }.to raise_error(TypeError)
    expect{ Log4r::FileOutputter.new('fa', :filename => Log4r::DEBUG) }.to raise_error(TypeError)
    expect{ Log4r::FileOutputter.new('fo', :filename => nil) }.to raise_error(TypeError)
    expect {
      Log4r::FileOutputter.new('fi', :filename => '/tmp/log4rails-test.log')
      Log4r::FileOutputter.new('fum', :filename => '/tmp/log4rails-test.log', :trunc => "true")
    }.not_to raise_error
    fo = Log4r::FileOutputter.new('food', :filename => '/tmp/log4rails-test.log', :trunc => false)
    expect(fo.trunc).to be false
    expect(fo.filename).to eq '/tmp/log4rails-test.log'
    expect(fo.closed?).to be false
    fo.close
    expect(fo.closed?).to be true
    expect(fo.level).to eq Log4r::OFF
  end
  
  it "tests outputter log methods" do
    o = Log4r::RspecOutputter.new('so1', :level => Log4r::WARN )
    # test to see if all of the methods are defined
    for mname in Log4r::LNAMES
      next if mname == 'OFF' || mname == 'ALL'
      expect(o).to respond_to(mname.downcase.to_sym)
    end
    # cuz the rest is broken
    # we rely on BasicFormatter's inability to reference a nil Logger to test
    # the log methods. Everything from WARN to FATAL should choke.
    # event = Log4r::LogEvent.new(nil, nil, nil, nil)
    # assert_nothing_raised { o.debug event }
    # assert_nothing_raised { o.info event }
    # assert_raise(Log4r::NameError) { o.warn event }
    # assert_raise(Log4r::NameError) { o.error event }
    # assert_raise(Log4r::NameError) { o.fatal event }
    # # now let's dynamically change the level and repeat
    # o.level = Log4r::ERROR
    # assert_nothing_raised { o.debug event}
    # assert_nothing_raised { o.info event}
    # assert_nothing_raised { o.warn event}
    # assert_raise(Log4r::NameError) { o.error event}
    # assert_raise(Log4r::NameError) { o.fatal event}
  end
  
  it "tests outputter only_at validation" do
    o = Log4r::RspecOutputter.new 'so2'
    expect{ o.only_at }.to raise_error(ArgumentError)
    expect{ o.only_at Log4r::ALL }.to raise_error(ArgumentError)
    expect{ o.only_at Log4r::OFF }.to raise_error(TypeError)
    l = Log4r::Logger.new('log4r')
    l.add o
    o.expect_log("DEBUG log4r: Outputter 'so2' writes only on DEBUG, ERROR") {
      expect{ o.only_at Log4r::DEBUG, Log4r::ERROR }.not_to raise_error
    }
    # cuz the rest is broken
    # test the methods as before
    # event = LogEvent.new(nil,nil,nil,nil)
    # assert_raise(NameError) { o.debug event}
    # assert_raise(NameError) { o.error event}
    # assert_nothing_raised { o.warn event}
    # assert_nothing_raised { o.info event}
    # assert_nothing_raised { o.fatal event}
  end
  
  it "tests file encoding" do
    if defined?( Encoding ) && ENV['RUBY_VERSION'] >= 'ruby-2.0.0'
      Encoding.default_internal = Encoding::UTF_8
      File.open( '/tmp/log4rails-test.log', 'w' ) { |f| f.write("\xC3\xBCmlat") }
      fenc = Log4r::FileOutputter.new('fenc', :filename => '/tmp/log4rails-test.log')
      event = Log4r::LogEvent.new(1, Log4r::Logger.root, nil, "\xC3\xBCmlat".force_encoding('ASCII-8BIT'))
      expect{ fenc.debug event }.not_to raise_error#(Encoding::UndefinedConversionError)
      fenc.close
    end
  end
  
  it "tests outputter threading" do
    ts = Thread.new {
      t = Thread.new {
        o = Log4r::StdoutOutputter.new 'so2'
        expect{ o.only_at Log4r::DEBUG, Log4r::ERROR }.not_to raise_error
        Thread.current.exit
      }
      t.join
    }
    ts.join
  end
  
end
