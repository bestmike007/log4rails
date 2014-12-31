if ENV['RUBY_VERSION'] == 'ruby-2.2.0'
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

module Kernel
  alias_method :normal_require, :require
  Log4rDynamicLoaded = []
  private
  def require(path)
    if path.start_with?("log4r")
      unless Log4rDynamicLoaded.index(path).nil?
        return
      end
      Log4rDynamicLoaded << path
      load File.join(File.dirname(__FILE__), "../lib/#{path}.rb")
      return
    end
    normal_require path
  end

  # This method reloads log4r. It's for tests only. It does not work if Log4r is included in other modules.
  def reload_log4r
    if Object.const_defined? :Log4r
      Log4r::NDC.clear
      Log4r::GDC.set $0
      Thread.current[Log4r::MDCNAME] = Hash.new
      Thread.main[Log4r::MDCNAME] = Hash.new
      Object.send :remove_const, :Log4r
      Kernel.send :remove_const, :Log4rDynamicLoaded
      Kernel.send :const_set, :Log4rDynamicLoaded, []
    end
    require 'log4r'
    require 'log4r/configurator'
    require 'log4r/staticlogger'
    require 'log4r/formatter/log4jxmlformatter'
    require 'log4r/outputter/udpoutputter'
    require 'log4r/outputter/consoleoutputters'
    require 'log4r/outputter/rspecoutputter'
    require 'log4r/yamlconfigurator'
  end
end