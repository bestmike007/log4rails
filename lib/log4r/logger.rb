# :include: rdoc/logger
#
# == Other Info
# 
# Version:: $Id$
# Author:: Leon Torres <leon(at)ugcs.caltech.edu>

require "log4r/outputter/outputter"
require "log4r/repository"
require "log4r/loggerfactory"
require "log4r/staticlogger"

module Log4r
  
  # See log4r/logger.rb
  class Logger
    attr_reader :name, :fullname, :path, :level, :parent
    attr_reader :additive, :trace, :outputters

    # Logger requires a name. The last 3 parameters are:
    #
    # level::     Do I have a level? (Otherwise, I'll inherit my parent's)
    # additive::  Am I additive?
    # trace::     Do I record the execution trace? (slows things a wee bit) 

    def initialize(_fullname, _level=nil, _additive=true, _trace=false)
      # validation
      raise ArgumentError, "Logger must have a name", caller if _fullname.nil?
      Log4rTools.validate_level(_level) unless _level.nil?
      validate_name(_fullname)
      
      # create the logger
      @fullname = _fullname
      @outputters = []
      @additive = _additive
      deal_with_inheritance(_level)
      LoggerFactory.define_methods(self)
      self.trace = _trace
      Repository[@fullname] = self
    end

    def validate_name(_fullname)
      parts = _fullname.split Log4rConfig::LoggerPathDelimiter
      for part in parts
        raise ArgumentError, "Malformed path", caller[1..-1] if part.empty?
      end
    end
    private :validate_name

    # Parses name for location in heiarchy, sets the parent, and
    # deals with level inheritance

    def deal_with_inheritance(_level)
      mypath = @fullname.split Log4rConfig::LoggerPathDelimiter
      @name = mypath.pop
      if mypath.empty? # then root is my daddy
        @path = ""
        # This is one of the guarantees that RootLogger gets created
        @parent = Logger.root
      else
        @path = mypath.join(Log4rConfig::LoggerPathDelimiter)
        @parent = Repository.find_ancestor(@path)
        @parent = Logger.root if @parent.nil?
      end
      # inherit the level if no level defined
      if _level.nil? then @level = @parent.level
      else @level = _level end
      Repository.reassign_any_children(self)
    end
    private :deal_with_inheritance

    # Set the logger level dynamically. Does not affect children.
    def level=(_level)
      Log4rTools.validate_level(_level)
      @level = _level
      LoggerFactory.define_methods(self)
      Logger.log_internal {"Logger '#{@fullname}' set to #{LNAMES[@level]}"}
      @level
    end

    # Return array of defined levels.
    def levels
      LNAMES
    end

    # Set the additivity of the logger dynamically. True or false.
    def additive=(_additive)
      @additive = _additive
      LoggerFactory.define_methods(self)
      Logger.log_internal {"Logger '#{@fullname}' is additive"}
      @additive
    end

    # Set whether the logger traces. Can be set dynamically. Defaults
    # to false and understands the strings 'true' and 'false'.
    def trace=(_trace)
      @trace =
        case _trace
        when "true", true then true
        else false end
      LoggerFactory.define_methods(self)
      Logger.log_internal {"Logger '#{@fullname}' is tracing"} if @trace
      @trace
    end

    # Please don't reset the parent
    def parent=(parent)
      @parent = parent
    end
    
    # Set the Outputters dynamically by name or reference. Can be done any
    # time.
    def outputters=(_outputters)
      @outputters.clear
      add(*_outputters)
    end  

    # Add outputters by name or by reference. Can be done any time.
    def add(*_outputters)
      for thing in _outputters
        o = (thing.kind_of?(Outputter) ? thing : Outputter[thing])
        # some basic validation
        unless o.kind_of?(Outputter)
          raise TypeError, "Couldn't find Outputter '#{thing}'"
        end
        @outputters.push o
        Logger.log_internal {"Added outputter '#{o.name}' to '#{@fullname}'"}
      end
      @outputters
    end

    # Remove outputters from this logger by name only. Can be done any time.
    def remove(*_outputters)
      for name in _outputters
        o = Outputter[name]
        @outputters.delete o
        Logger.log_internal {"Removed outputter '#{o.name}' from '#{@fullname}'"}
      end
    end

    def is_root?; false end

    def ==(other)
      return true if self.object_id == other.object_id
    end

    # fix for rails 4+
    # <tk>
    def formatter
      nil
    end
    # </tk>
  end

end
