require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "loads LNAMES properly" do
    levels = [:ALL, :DEBUG, :INFO, :WARN, :ERROR, :FATAL, :OFF, :LEVELS].map{|l| Log4r.const_get l }
    expect(levels).to eq [0, 1, 2, 3, 4, 5, 6, 7]
    expect(Log4r::LNAMES.size).to eq 7
    expect(Log4r::Logger.root.levels).to be Log4r::LNAMES
  end
  
  it "check bad input and bounds for validate_level" do
    7.times{|i| expect{Log4r::Log4rTools.validate_level(i)}.not_to raise_error }
    [-1, Log4r::LEVELS, String, 'bogus'].each { |l|
      expect{Log4r::Log4rTools.validate_level(l)}.to raise_error(ArgumentError)
    }
  end
  
  it "decode_bool turns a string 'true' into true and so on" do
    cases = [
      ['true',  false,  true],
      [true,    false,  true],
      ['false', true,   false],
      [false,   true,   false],
      [nil,     true,   true],
      [nil,     false,  false],
      [String,  true,   true],
      [String,  false,  false]
    ]
    [:data, 'data'].each do |key|
      cases.each do |values|
        expect(Log4r::Log4rTools.decode_bool({ key => values[0] }, :data, values[1])).to eq values[2]
      end
    end
  end
  
  it "tests camel underscore" do
    expect(Log4r::Log4rTools.underscore("HelloWorld")).to eq 'hello_world'
  end
  
  it "cannot configure invalid formatter" do
    configurator = Log4r::Configurator::OutputterConfigurator.new(nil, {
      name: 'test', type: 'RspecOutputter', formatter: { type: 'BogusFormatter' }
    })
    expect {
      configurator.do_config
    }.to raise_error(Log4r::ConfigError)
  end
  
  it do
    expect {
      logger = Log4r::Logger.new("log4r")
      outputter =  Log4r::RollingFileOutputter.new("foo", :filename => '/tmp/log4rails-test.log', :maxtime => 1)
      logger.outputters = outputter
      
      sleep 2
      logger.warn("Hello")
    }.not_to raise_error
  end
  
end
