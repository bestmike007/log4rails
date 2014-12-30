require_relative "rspec_helper"

include Log4r

RSpec.describe "Log4r" do
  
  it "shows the file name when GDC.get() is called" do
    expect(File.basename(GDC.get)).to eq 'rspec'
  end
  
  it "can set GDC stack" do
    expect{ GDC.set("testGDCset") }.not_to raise_error
    expect(GDC.get).to eq "testGDCset"
  end
  
  it "work on threads" do
    expect{ GDC.set("testGDCset") }.not_to raise_error
    t = Thread.new("test GDC thread") do |name|
      expect{ GDC.set("somethingelse") }.to raise_error(RuntimeError)
    end
    t.join
    expect(GDC.get).to eq "testGDCset"
  end
  
end
