require 'log4r'
require 'log4r/configurator'
require 'log4r/staticlogger'
require 'log4r/formatter/log4jxmlformatter'
require 'log4r/outputter/udpoutputter'
require 'log4r/outputter/consoleoutputters'
require 'log4r/outputter/rspecoutputter'
require 'log4r/xml_configurator'
require 'log4r/yaml_configurator'

# This method reloads log4r. It's for tests only. It does not work if Log4r is included in other modules.
def reload_log4r
  Log4r.reset!
end

# Setup test coverage with codeclimate.
$coverage = false
if ENV['RUBY_VERSION'] == 'ruby-2.2.0' || !ENV.has_key?('CODECLIMATE_REPO_TOKEN')
  $coverage = true
  require 'simplecov'
  require 'codeclimate-test-reporter'
  
  SimpleCov.coverage_dir('coverage')
  SimpleCov.add_filter 'lib/log4r/lib'
  SimpleCov.formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter
  ]
  SimpleCov.start CodeClimate::TestReporter.configuration.profile
  
  RSpec.configure do |config|
    config.after(:suite) {
      puts "DONE"
    }
  end
end

