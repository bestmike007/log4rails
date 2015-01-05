# :include: rdoc/GDC
#
# == Other Info
# 
# Version:: $Id$
# Author:: Colby Gutierrez-Kraybill <colby(at)astro.berkeley.edu>

require 'monitor'

module Log4r
  GDCNAME = "log4rGDC"
  $globalGDCLock = Monitor.new

  # See log4r/GDC.rb
  class GDC < Monitor
    
    private_class_method :new
    
    class << self

      def clear
        Thread.main[GDCNAME] = ""
      end
  
      def get
        $globalGDCLock.synchronize do
      	  Thread.main[GDCNAME] ||= $0
        end
        Thread.main[GDCNAME]
      end
  
      def set(a_name)
        if Thread.current != Thread.main
  	      raise "Can only initialize Global Diagnostic Context from Thread.main"
        end
        $globalGDCLock.synchronize do
  	      Thread.main[GDCNAME] = a_name
        end
      end
      
    end # class << GDC
    
  end # GDC
  
end

