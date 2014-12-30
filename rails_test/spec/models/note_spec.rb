require 'rails_helper'

RSpec.describe Note, :type => :model do
  
  it "has log4r logger" do
    expect(Note.logger.instance_of?(Log4r::Logger)).to be true
  end
  
end
