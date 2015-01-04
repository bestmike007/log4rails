require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) { reload_log4r }
  
  it "loads yaml configuration without exception" do
    expect {
      Log4r::YamlConfigurator.load_yaml_file(File.join(File.dirname(__FILE__), 'testyaml_injection.yaml'))
    }.not_to raise_error
  end
  
  it "tests array params in yaml configuration" do
    
    class TestYamlOutputter < Log4r::Outputter
      # expose array parameter
      attr_reader :array_param
    
      def initialize(name, hash = {})
        @array_param = hash[:array_param]
        super
      end
      
    end
    
    expect {
      Log4r::YamlConfigurator.load_yaml_file(File.join(File.dirname(__FILE__), 'testyaml_arrays.yaml'))
    }.not_to raise_error
    log = Log4r::Logger['mylogger']
    expect(log.outputters.first.array_param).to be_an(Array)
    expect(log.outputters.first.array_param[2]).to eq 'wilma@bar.com'
  end
  
end
