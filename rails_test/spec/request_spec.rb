require 'rails_helper'

RSpec.describe "Note", :type => :request do
  
  it do
    expected = [
      /^\d{2}:\d{2}:\d{2} \[rails::controllers\] DEBUG: Hello/,
      /^\d{2}:\d{2}:\d{2} \[rails\] (INFO|WARN): GET \/ \(TIMING\[ms\]: sum:[\d\.]+ db:[\d\.]+ view:[\d\.]+\)$/,
      /^\d{2}:\d{2}:\d{2} \[rails::params\] INFO: request params: {"controller":"home","action":"index"}$/
    ]
    rspec_outputter.dump_logs {
      get "/"
    }.each { |l| expect(l).to match(expected.shift) }
  end
  
end
