require "rspec_helper"

One=<<-EOX
<log4r_config><pre_config><custom_levels> Foo </custom_levels>
</pre_config></log4r_config>
EOX
Two=<<-EOX
<log4r_config><pre_config><global level="DEBUG"/></pre_config></log4r_config>
EOX
Three=<<-EOX
<log4r_config><pre_config><custom_levels>Foo</custom_levels>
<global level="Foo"/></pre_config>
</log4r_config>
EOX

RSpec.describe "Log4r" do
  
  before(:each) { reload_log4r }
  
  it "loads xml config `One`" do
    expect {
      Log4r::XmlConfigurator.load_xml_string(One)
      expect(Log4r::Foo).to eq 1
      expect(Log4r::Logger.global.level).to eq Log4r::ALL
    }.not_to raise_error
  end
  
  it "loads xml config `Two`" do
    expect {
      Log4r::XmlConfigurator.load_xml_string(Two)
      expect(Log4r::Logger.global.level).to eq Log4r::DEBUG
    }.not_to raise_error
  end
  
  it "loads xml config `Three`" do
    expect {
      Log4r::XmlConfigurator.load_xml_string(Three)
      expect(Log4r::Foo).to eq 1
      expect(Log4r::Logger.global.level).to eq Log4r::Foo
    }.not_to raise_error
  end
  
  it "loads xml config from file" do
    expect {
      Log4r::XmlConfigurator.load_xml_file(File.join(File.dirname(__FILE__), 'testconf.xml'))
      a = Log4r::Logger['first::second']
      Log4r::Outputter['SO'].expect_log(/^\d+ second Bing> what the heck$/) {
        a.bing "what the heck"
      }
    }.not_to raise_error
  end
  
end
