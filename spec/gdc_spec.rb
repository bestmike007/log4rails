require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "shows the file name when GDC.get() is called" do
    expect(File.basename(Log4r::GDC.get)).to eq 'rspec'
  end
  
  it "can set GDC stack" do
    expect{ Log4r::GDC.set("testGDCset") }.not_to raise_error
    expect(Log4r::GDC.get).to eq "testGDCset"
    Log4r::GDC.clear
    expect(Log4r::GDC.get).to eq ""
  end
  
  it "ensure that GDC does not work on threads" do
    expect{ Log4r::GDC.set("testGDCset") }.not_to raise_error
    t = Thread.new("test GDC thread") do |name|
      expect{ Log4r::GDC.set("somethingelse") }.to raise_error(RuntimeError)
    end
    t.join
    expect(Log4r::GDC.get).to eq "testGDCset"
  end
  
end
