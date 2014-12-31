require 'rails_helper'

RSpec.describe Note, :type => :model do
  
  it "has log4r logger" do
    rspec_outputter.expect_log(/^\d{2}:\d{2}:\d{2} \[rails::models\] DEBUG: Hello$/) {
      Note.logger.debug "Hello"
    }
  end
  
end

RSpec.describe User, :type => :model do
  
  it "has log4r logger" do
    rspec_outputter.expect_log(/^\d{2}:\d{2}:\d{2} \[rails::models\] DEBUG: Hello$/) {
      User.logger.debug "Hello"
    }
  end
  
end