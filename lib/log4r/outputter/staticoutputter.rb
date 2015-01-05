# :nodoc:
module Log4r

  class Outputter < Monitor
    # Retrieve an outputter.
    class << self
      def [](name)
        out = outputters[name]
        if out.nil?
          return case name
          when 'stdout' then StdoutOutputter.new 'stdout'
          when 'stderr' then StderrOutputter.new 'stderr'
          else nil end
        end          
        out
      end
      def stdout; Outputter['stdout'] end
      def stderr; Outputter['stderr'] end
      # Set an outputter.
      def []=(name, outputter)
        outputters[name] = outputter
      end
      # Yields each outputter's name and reference.
      def each
        outputters.each {|name, outputter| yield name, outputter}
      end
      def each_outputter
        outputters.each_value {|outputter| yield outputter}
      end
      
      private
      def outputters
        @outputters ||= {}
      end
    end
  end
end
