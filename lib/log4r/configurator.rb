# :include: rdoc/configurator
#
# == Other Info
#
# Version:: $Id$

require "log4r/logger"
require "log4r/logserver"
require "log4r/outputter/staticoutputter"

# TODO: catch unparsed parameters #{FOO} and die
module Log4r
  
  # Gets raised when Configurator encounters invalid configuration.
  class ConfigError < Exception
  end

  # The basic configurator loads config from a hash object. Descendants translate configuration written in specific format into hash config add call Configurator#config(hash_config)
  
  class Configurator
    
    class << self
      
      def config(hash_config)
        self.new.load_config(hash_config)
      end
    
      alias_method :load_config, :config
      
      #######
      private
      #######
      
      def config_parser(parser, format_name)
        eigen = class << self; self; end
        eigen.const_set :Parser, parser
        eigen.class_eval %{
          def load_#{format_name}(str_or_file)
            load_config Parser.new(str_or_file).parse
          end
          # Given a filename, loads the XML configuration for Log4r.
          def load_#{format_name}_file(filename)
            load_#{format_name}(File.new(filename))
          end
          alias_method :load_#{format_name}_string, :load_#{format_name}
        }
      end
      
    end
    
    def load_config(hash_config)
      internal_load(hash_config)
    end

    #######
    private
    #######
    
    # Initialize custom levels or load default levels
    def custom_levels(levels)
      return Logger.root if levels.nil? || levels.size == 0
      Log4r.define_levels(*levels)
    end
    
    # Load all configuration from a hash and initialize everything
    def internal_load(hash_config)
      pre_config(hash_config[:pre_config])
      
      [:outputter, :logger, :logserver].each do |item|
        (hash_config["#{item}s".to_sym] || []).each do |c|
          send "config_#{item}".to_sym, c
        end
      end
    end

    def pre_config(c)
      return Logger.root if c.nil?
      custom_levels(c[:custom_levels])
      global_level_config(c[:global_level])
      @params = c[:parameters] || {}
    end
    
    def global_level_config(level)
      return if level.nil?
      level = LNAMES.index(level)     # find value in LNAMES
      Log4rTools.validate_level(level)  # choke on bad level
      Logger.global.level = level
    end
    
    def config_outputter(c)
      OutputterConfigurator.new(@params, c).do_config
    end

    def config_logger(c)
      l = Logger.new c[:name]
      config_logger_common(l, c)
    end

    def config_logserver(c)
      l = LogServer.new c[:name], c[:uri]
      config_logger_common(l, c)
    end

    def config_logger_common(l, c)
      level = c[:level]
      l.level = LNAMES.index(level) unless level.nil?
      l.additive = Log4rTools.decode_bool(c, :additive, l.additive)
      l.trace = Log4rTools.decode_bool(c, :trace, l.trace)
      # and now for outputters
      (c[:outputters] || []).each { |o| l.add o }
    end
  end
  
  class Configurator
    
    # config and register outputters from the hash configuration section
    
    class OutputterConfigurator
      
      def initialize(params, config)
        @params = params || {}
        @config = config
        raise "Expect global parameters to be a hash" if !@params.instance_of?(Hash)
      end
      
      def do_config
        return unless @config.instance_of?(Hash)
        internal_config_outputter
      rescue ConfigError
        raise
      rescue Exception => ae
        raise ConfigError, "Problem creating outputter: #{ae.message}", ae.backtrace
      end
      
      #######
      private
      #######
      
      def outputter_name
        raise ConfigError, "Outputter name is required." if @config[:name].nil?
        @config[:name]
      end
      
      def outputter_type
        raise ConfigError, "Outputter type is required." if @config[:type].nil?
        @config[:type]
      end
      
      def formatter_config
        @config[:formatter].instance_of?(Hash) ? @config[:formatter] : nil
      end
  
      def internal_config_outputter
        config_outputter_level
        config_formatter
        
        Log4rTools.load_outputter(outputter_type).new(outputter_name, fence_params)
      
        config_outputter_only_at
      end
      
      def config_outputter_level
        if @config.has_key? :level
          level = @config[:level]
          Log4rTools.validate_level(LNAMES.index(level))
          @config[:level] = LNAMES.index(level)
        end
      end
      
      def config_outputter_only_at
        if @config.has_key? :only_at
          only_at = @config[:only_at]
          only_levels = (only_at.instance_of?(Array) ? only_at : [only_at]).map{ |l| LNAMES.index(l) }
          Outputter[outputter_name].only_at(*only_levels) if only_levels.size > 0
        end
      end
  
      def config_formatter
        return if formatter_config.nil?
        @config[:formatter] = Log4rTools.load_formatter(formatter_config[:type]).new fence_params(formatter_config)
      rescue Exception => ae
        raise ConfigError, "Problem creating outputter: #{ae.message}", ae.backtrace
      end
  
      # Does the fancy parameter to hash argument transformation
      def fence_params(c=@config)
        config = c.clone
        [:name, :type, :only_at].each { |k| config.delete k }
        config.each { |k, v| param_sub(v) }
        config
      end
      
      # Substitues any #{foo} in the configuration with params[:foo]
      def param_sub(param)
        if param.instance_of? String
          @params.each { |k, v| param.sub!('#{%s}' % k, v) }
        elsif param.instance_of?(Array)
          param.each { |v| param_sub(v) }
        end
      end
    end
  end
end
