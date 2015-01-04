require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
  }
  
  it "test define levels #1" do
    expect { Log4r.define_levels "Foo", "Bar", "Baz" }.not_to raise_error
  end
  
  it "test define levels #2" do
    expect { Log4r.define_levels }.not_to raise_error
  end
  
  it "test define levels #3" do
    expect { Log4r.define_levels "Bogus", "Levels" }.not_to raise_error
  end
  
  it "test define levels #4" do
    expect { Log4r.define_levels "lowercase" }.to raise_error(TypeError)
  end
  
  it "test define levels #5" do
    expect { Log4r.define_levels "With space" }.to raise_error(TypeError)
  end
end
