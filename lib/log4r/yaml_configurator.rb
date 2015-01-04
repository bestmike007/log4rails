# :include: rdoc/yamlconfigurator
#
# == Other Info
#
# Version: $Id$

require "log4r/configurator"

require 'yaml'

module Log4r

  # See log4r/yamlconfigurator.rb
  class YamlConfigurator < Configurator
    
    class YamlConfigParser
      
      def initialize(yaml_docs)
        @doc = nil
        YAML.load_documents(yaml_docs){ |doc|
          doc.has_key?( 'log4r_config') and @doc = doc['log4r_config'] and break
        }
        if @doc.nil?
          raise ConfigError, "Key 'log4r_config:' not defined in yaml documents", caller[1..-1]
        end
        @config = nil
      end
      
      def parse
        if @config.nil?
          actual_parse
        end
        @config
      end
      
      #######
      private
      #######
      
      def actual_parse
        @config = @doc.clone
        parse_global_level
        key_to_sym(@config)
      end
  
      def parse_global_level
        return unless @config.has_key?('pre_config')
        global_level = nil
        ['global', 'root'].each do |node|
          if @config['pre_config'].has_key?(node)
            puts "Config global level in #{node} is deprecated. use global_level instead: " + %{
              pre_config:
                global_level: DEBUG
            }
            global_level = @config['pre_config'][node]['level']
          end
        end
        unless global_level.nil?
          @config['pre_config']['global_level'] ||= global_level
        end
      end
      
      def array_key_to_sym(arr)
        arr.each do |item|
          if item.instance_of?(Hash)
            key_to_sym(item)
          elsif item.instance_of?(Array)
            array_key_to_sym(item)
          end
        end
      end
      
      def key_to_sym(hash)
        keys = []
        hash.each do |k, v|
          unless k.instance_of?(Symbol)
            keys << k
          end
          if v.instance_of?(Hash)
            key_to_sym(v)
          elsif v.instance_of?(Array)
            array_key_to_sym(v)
          end
        end
        keys.each do |k|
          hash[k.to_sym] = hash.delete(k)
        end
      end
      
    end
    
    class << self
      config_parser(YamlConfigParser, :yaml)
    end
  end
end

