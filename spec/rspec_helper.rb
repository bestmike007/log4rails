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
      # LNAMES.each { |l| Log4r.send :remove_const, l.to_sym } rescue nil
      # Log4r.send :remove_const, :LNAMES
      # Log4r.send :remove_const, :LEVELS rescue nil
      # Log4r.send :remove_const, :MaxLevelLength rescue nil
      # Log4r.send :const_set, :LNAMES, ['ALL']
      # Log4r.send :const_set, :ALL, 0
      # Log4r.send :remove_const, :RootLogger rescue nil
      # Log4r.send :remove_const, :Repository rescue nil
      # load File.join(File.dirname(__FILE__), "../lib/log4r/repository.rb")
      # load File.join(File.dirname(__FILE__), "../lib/log4r/logger.rb")
      
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
    require 'log4r/yamlconfigurator'
    
  end
end