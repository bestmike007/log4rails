# :include: rdoc/MDC
#
# == Other Info
# 
# Version:: $Id$
# Author:: Colby Gutierrez-Kraybill <colby(at)astro.berkeley.edu>

require 'monitor'

module Log4r
  MDCNAME = "log4rMDC"
  MDCNAMEMAXDEPTH = "log4rMDCMAXDEPTH"
  $globalMDCLock = Monitor.new

  # See log4r/MDC.rb
  class MDC < Monitor
    private_class_method :new
    
    class << self
      
      def check_thread_instance
        # need to interlock here, so that if
        # another thread is entering this section
        # of code before the main thread does,
        # then the main thread copy of the MDC
        # is setup before then attempting to clone
        # it off
        if ( Thread.current[MDCNAME] == nil ) then
        	$globalMDCLock.synchronize do 
        	 Thread.main[MDCNAME] ||= Hash.new
        	 clone_from_main if Thread.current != Thread.main
        	end
        end
      end
      
      def clone_from_main
        Thread.current[MDCNAME] = Thread.main[MDCNAME].clone
      end
      private :clone_from_main
  
      def get(a_key)
        check_thread_instance()
        Thread.current[MDCNAME][a_key];
      end
  
      def get_context
        check_thread_instance()
        return Thread.current[MDCNAME].clone
      end
  
      def put(a_key, a_value)
        check_thread_instance()
        Thread.current[MDCNAME][a_key] = a_value
      end
  
      def remove(a_key)
        check_thread_instance()
        Thread.current[MDCNAME].delete(a_key)
      end
    end
  end
end
