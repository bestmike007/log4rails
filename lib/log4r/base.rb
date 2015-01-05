# :nodoc:
require "log4r/config"

module Log4r
  ALL = 0
  LNAMES = ['ALL']
  
  class << self
    # Defines the log levels of the Log4r module at runtime. It is given
    # either the default level spec (when root logger is created) or the
    # user-specified level spec (when Logger.custom_levels is called).
    #
    # The last constant defined by this method is OFF. Other level-sensitive 
    # parts of the code check to see if OFF is defined before deciding what 
    # to do. The typical action would be to force the creation of RootLogger 
    # so that the custom levels get loaded and business can proceed as usual.
    #
    # For purposes of formatting, a constant named MaxLevelLength is defined
    # in this method. It stores the max level name string size.
    def define_levels(*levels) #:nodoc:
      return if initialized?
      for i in 0...levels.size
        name = levels[i].to_s
        Log4rTools.validate_level_name! name
        self.const_set name.to_sym, i + 1
        LNAMES << name
      end
      finalize_levels
    end
    
    # Detect if Log4r is initialized. 
    def initialized?
      const_defined? :OFF
    end
    
    # experimental: reset log4r to unconfigured status.
    def reset!
      return if !initialized?
      file_pattern = File.join(File.dirname(__FILE__), "%s.rb")
      class_eval %{
        # resets XDC
        Log4r::NDC.clear
        Log4r::GDC.set $0
        Thread.current[Log4r::MDCNAME] = Hash.new
        Thread.main[Log4r::MDCNAME] = Hash.new
        # resets levels
        (LNAMES + [:LNAMES, :LEVELS, :MaxLevelLength, :RootLogger]).each { |c| remove_const c rescue nil }
        ALL = 0
        LNAMES = ['ALL']
        # reset RootLogger & Repositories.
        load '#{file_pattern}' % "rootlogger"
        Outputter.instance_eval "@outputters = Hash.new"
        Logger::Repository.instance.instance_eval "@loggers = Hash.new"
      }
    end
    
    #######
    private
    #######
    
    def finalize_levels
      return if initialized?
      LNAMES << 'OFF'
      self.const_set :LEVELS, LNAMES.size
      self.const_set :OFF, LEVELS - 1
      self.const_set :MaxLevelLength, Log4rTools.max_level_str_size
    end
  end

  # Some common functions 
  module Log4rTools
    class << self
      # Raises ArgumentError if level argument is an invalid level. Depth
      # specifies how many trace entries to remove.
      def validate_level(level, depth=0)
        unless valid_level?(level)
          raise ArgumentError, "Log level must be in 0..#{LEVELS}",
                caller[1..-(depth + 1)]
        end
      end
      
      def valid_level?(lev)
        not lev.nil? and lev.kind_of?(Numeric) and lev >= ALL and lev <= OFF
      end
      
      # Raise TypeError if the given level name is not legal.
      def validate_level_name!(lname)
        lname = lname.to_s
        if lname =~ /\s/ or lname !~ /^[A-Z]/
          raise TypeError, "#{lname} is not a valid Ruby Constant name", caller
        end
      end
      
      # The maximum length of the string representations all the level names.
      def max_level_str_size
        size = 0
        LNAMES.each {|i| size = i.length if i.length > size}
        size
      end
    
      # Shortcut for decoding 'true', 'false', true, false or nil into a bool
      # from a hash parameter. E.g., it looks for true/false values for
      # the keys 'symbol' and :symbol.
  
      def decode_bool(hash, symbol, default)
        data = hash[symbol]
        data = hash[symbol.to_s] if data.nil?
        return case data
          when 'true',true then true
          when 'false',false then false
          else default
          end
      end
  
      # Camel case to underscore string.
      def underscore(str)
        str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      end
  
      # Splits comma-delimited lists with arbitrary \s padding
      def comma_split(string)
        string.split(/\s*,\s*/).collect {|s| s.strip}
      end
      
      # http://stackoverflow.com/questions/13162607/does-object-const-get-work-with-strings-i-get-a-wrong-constant-name-error
      def get_class(type)
        raise "Type is not configured." if type.nil?
        type.split("::").inject(Object) { |n,c| n.const_get(c) }
      end
      
      def load_outputter(type)
        if type =~ /[a-zA-Z]+Outputter/
          begin require "log4r/outputter/#{type.downcase}"
          rescue Exception
          end
          type = "Log4r::#{type}"
        end
        get_class(type)
      end
      
      def load_formatter(type)
        native_formatters = {
          'PatternFormatter' => 'log4r/formatter/patternformatter',
          'Log4jXmlFormatter' => 'log4r/formatter/log4jxmlformatter'
        }
        if native_formatters.has_key? type
          require native_formatters[type]
        else
          require "log4r/formatter/formatter"
        end
        if type =~ /[a-zA-Z]+Formatter/
          type = "Log4r::#{type}"
        end
        get_class(type)
      end
      
    end
  end
end
