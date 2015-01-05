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
    Log4r::NDC.push("ndc1")
    Log4r::NDC.push("ndc2")
    a = Log4r::NDC.clone_stack()
    Log4r::NDC.remove()
    expect(Log4r::NDC.get).to eq ""
    Log4r::NDC.inherit(a)
    expect(Log4r::NDC.get).to eq "ndc1 ndc2"
    expect(Log4r::NDC.get_depth).to eq 2
    expect(Log4r::NDC.peek).to eq 'ndc2'
    Log4r::NDC.set_max_depth 2
    Log4r::NDC.push("ndc3")
    expect(Log4r::NDC.get).to eq "ndc1 ndc2"
    expect(Log4r::NDC.get_depth).to eq 2
  end
  
  it "tests NDC inherit" do
    expect{ Log4r::NDC.inherit(:not_array) }.to raise_error
    expect{ Log4r::NDC.inherit('not_array') }.to raise_error
    expect{ Log4r::NDC.inherit(123) }.to raise_error
  end
  
end
