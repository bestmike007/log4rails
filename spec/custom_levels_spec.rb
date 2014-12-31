require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "supports custom levels" do
    expect { Log4r::Configurator.custom_levels "Foo", "Bar", "Baz" }.not_to raise_error
    expect { Log4r::Configurator.custom_levels }.not_to raise_error
    expect { Log4r::Configurator.custom_levels "Bogus", "Levels" }.not_to raise_error
  end
  
  it "validates invalid custom level names" do
    expect { Log4r::Configurator.custom_levels "lowercase" }.to raise_error(TypeError)
    expect { Log4r::Configurator.custom_levels "With space" }.to raise_error(TypeError)
  end
  
end
