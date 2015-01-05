require "log4r/repository"
# :nodoc:
module Log4r
  class Logger
    # RootLogger should be retrieved with Logger.root or Logger.global.
    # It's supposed to be transparent.
    #--
    # We must guarantee the creation of RootLogger before any other Logger
    # or Outputter gets their logging methods defined. There are two 
    # guarantees in the code:
    #
    # * Logger#deal_with_inheritance - calls RootLogger.instance when
    #   a new Logger is created without a parent. Parents must exist, therefore
    #   RootLogger is forced to be created.
    #
    # * OutputterFactory.create_methods - Calls Logger.root first. So if
    #   an Outputter is created, RootLogger is also created.
    #
    # When RootLogger is created, it calls
    # Log4r.define_levels(*Log4rConfig::LogLevels). This ensures that the 
    # default levels are loaded if no custom ones are.
  
    class RootLogger < Logger
      include Singleton
  
      def initialize
        Log4r.define_levels(*Log4rConfig::LogLevels) # ensure levels are loaded
        @level = ALL
        @outputters = []
        Repository['root'] = self
        Repository['global'] = self
        LoggerFactory.undefine_methods(self)
      end
  
      def is_root?; true end
  
      # Set the global level. Any loggers defined thereafter will
      # not log below the global level regardless of their levels.
  
      def level=(alevel); @level = alevel end
  
      # Does nothing
      def outputters=(foo); end
      # Does nothing
      def trace=(foo); end
      # Does nothing
      def additive=(foo); end
      # Does nothing
      def add(*foo); end
      # Does nothing
      def remove(*foo); end
    end
  end
end
