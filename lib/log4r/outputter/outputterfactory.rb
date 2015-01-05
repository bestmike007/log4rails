# :nodoc:
# Version: $Id$

require "log4r/base"
require "log4r/repository"

require 'monitor'

module Log4r
class Outputter < Monitor

  class OutputterFactory #:nodoc:
    include Singleton
    class << self
      # handles two cases: logging above a level (no second arg specified)
      # or logging a set of levels (passed into the second argument)
      def create_methods(out, levels=nil)
        Logger.root # force levels to be loaded

        # first, undefine all the log levels
        for mname in LNAMES
          switch_log_definition :off, mname.downcase, out
        end
        if (levels || []).include? OFF
          raise TypeError, "Can't log only_at OFF"
        end
        return out if out.level == OFF

        for lev in (levels || (out.level...LEVELS))
          switch_log_definition :on, LNAMES[lev].downcase, out
        end
        return out
      end
      
      #######
      private
      #######
      
      def switch_log_definition(on_off, mname, out)
        return if mname == 'off' || mname == 'all'
        m = on_off == :on ? Proc.new {|logevent|canonical_log(logevent)} : Proc.new{|logevent|}
        out.define_singleton_method mname.to_sym, m
      end
    end
  end

end
end
