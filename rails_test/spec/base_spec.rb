require 'rails_helper'

RSpec.describe "Log4rail Setup" do
  
  it "everything is log4r logger" do
    expect(Object.logger).to be Log4r::Logger.root
    expect(String.logger).to be Log4r::Logger.root
    expect(logger).to be Log4r::Logger.root
  end
  
  it 'initialized controller loggers' do
    expect(ActionController::Base.logger).to be_a Log4r::Logger
    expect(ActionController::Base.logger.fullname).to eq('rails::controllers')
    expect(ApplicationController.logger).to be ActionController::Base.logger
  end
  
  it 'initialized model loggers' do
    expect(ActiveRecord::Base.logger).to be_a Log4r::Logger
    expect(ActiveRecord::Base.logger.fullname).to eq('rails::models')
    expect(Note.logger).to be ActiveRecord::Base.logger
    expect(User.logger).to be ActiveRecord::Base.logger
  end
  
end
