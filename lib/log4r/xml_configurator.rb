# :include: rdoc/configurator
#
# == Other Info
#
# Version:: $Id$

require "log4r/configurator"

module Log4r
  
  begin
    require 'rexml/document'
    HAVE_REXML = true
    REXML::Element.class_eval %-
      def value_of(elmt)
        val = attributes[elmt]
        if val.nil?
          sub = elements[elmt]
          val = sub.text unless sub.nil?
        end
        val
      end
    -
  rescue LoadError
    HAVE_REXML = false
  end

  # See log4r/configurator.rb
  class XmlConfigurator < Configurator
    
    include REXML if HAVE_REXML
    
    class XmlConfigParser
      
      def initialize(doc)
        unless HAVE_REXML
          raise LoadError, "Need REXML to load XML configuration", caller[1..-1]
        end
        @config = nil
        @root = REXML::Document.new(doc).elements['//log4r_config']
        if @root.nil?
          raise ConfigError, "<log4r_config> element not defined", caller[1..-1]
        end
      end
      
      # Parse and cache the configuration as hash
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
        @config = {}
        parse_pre_config(@root.elements['pre_config'])
        ['outputter', 'logger', 'logserver'].each do |item|
          @root.elements.each(item) { |e| parse_into item, e }
        end
      end
  
      def parse_pre_config(e)
        return if e.nil?
        @config[:pre_config] = { :parameters => {} }
        parse_custom_levels(e.elements['custom_levels'])
        global_config(e.elements['global'])
        global_config(e.elements['root'])
        parse_parameters(e.elements['parameters'])
        e.elements.each('parameter') { |p| parse_parameter(p) }
      end
  
      def parse_custom_levels(e)
        return if e.nil? or e.text.nil?
        @config[:pre_config][:custom_levels] = Log4rTools.comma_split(e.text)
      rescue TypeError => te
        raise ConfigError, te.message, caller[1..-4]
      end
      
      def global_config(e)
        return if e.nil?
        global_level = e.value_of 'level'
        return if global_level.nil?
        @config[:pre_config][:global_level] = global_level
      end
  
      def parse_parameters(e)
        return if e.nil?
        e.elements.each{ |p| @config[:pre_config][:parameters][p.name.to_sym] = p.text }
      end
  
      def parse_parameter(e)
        @config[:pre_config][:parameters][e.value_of('name').to_sym] = e.value_of 'value'
      end
  
      def parse_into(config_name, e)
        key = "#{config_name}s".to_sym
        @config[key] ||= []
        config = xml_node_to_hash(e)
        case config_name
        when 'outputter'
          parse_formatter(config, e)
          parse_array('only_at', config, e)
        when "logger"
          parse_array('outputters', config, e)
        end
        @config[key] << config
      end
      
      def parse_formatter(config, e)
        formatter = e.elements["formatter"]
        unless formatter.nil?
          config[:formatter] = xml_node_to_hash(formatter)
        end
      end
      
      def parse_array(key, config, e)
        node = e.elements[key.to_s]
        unless node.nil?
          config[key.to_sym] = Log4rTools.comma_split(node.text)
        end
      end
      
      def xml_node_to_hash(e)
        hash = {}
        e.attributes.each_attribute { |p|
          hash[p.name.to_sym] = p.value
        }
        e.elements.each { |p|
          hash[p.name.to_sym] = p.text
        }
        return hash
      end
      
    end
    
    config_parser(XmlConfigParser, :xml)

  end
end
