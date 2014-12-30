require 'rails_helper'

RSpec.describe User, :type => :model do
  
  it "has log4r logger" do
    expect(User.logger.instance_of?(Log4r::Logger)).to be true
  end
  
end
