require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "tests NDC remove push" do
    Log4r::NDC.remove()
    Log4r::NDC.push("ndc")
    expect(Log4r::NDC.get).to eq "ndc"
    Log4r::NDC.push("ndc")
    expect(Log4r::NDC.get).to eq "ndc ndc"
  end
  
  it "tests NDC remove, push, clone, and inherit" do
    Log4r::NDC.remove()
    Log4r::NDC.push("ndc")
    Log4r::NDC.push("ndc")
    a = Log4r::NDC.clone_stack()
    Log4r::NDC.remove()
    expect(Log4r::NDC.get).to eq ""
    Log4r::NDC.inherit(a)
    expect(Log4r::NDC.get).to eq "ndc ndc"
  end
  
end
