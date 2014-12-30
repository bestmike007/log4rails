require_relative "rspec_helper"

include Log4r

RSpec.describe "Log4r" do
  
  it "supports custom levels" do
    expect { Configurator.custom_levels "Foo", "Bar", "Baz" }.not_to raise_error
    expect { Configurator.custom_levels }.not_to raise_error
    expect { Configurator.custom_levels "Bogus", "Levels" }.not_to raise_error
  end
  
  it "validates invalid custom level names" do
    expect { Configurator.custom_levels "lowercase" }.to raise_error(TypeError)
    expect { Configurator.custom_levels "With space" }.to raise_error(TypeError)
  end
  
end
