# :nodoc:
# Version:: $Id$

require "log4r/outputter/iooutputter"
require "log4r/staticlogger"

module Log4r

  # Convenience wrapper for File. Additional hash arguments are:
  #
  # [<tt>:filename</tt>]   Name of the file to log to.
  # [<tt>:trunc</tt>]      Truncate the file?
  class FileOutputter < IOOutputter
    attr_reader :trunc, :filename

    def initialize(_name, hash={})
      super(_name, nil, hash)

      @trunc = Log4rTools.decode_bool(hash, :trunc, false)
      @filename = (hash[:filename] or hash['filename'])
      @create = Log4rTools.decode_bool(hash, :create, true)
      @options = hash

      validate_file
      create_file
    end
    
    #######
    private
    #######
    
    def validate_file
      if @filename.class != String
        raise TypeError, "Argument 'filename' must be a String", caller
      end
      if FileTest.exist?( @filename )
        if not FileTest.file?( @filename )
          raise StandardError, "'#{@filename}' is not a regular file"
        elsif not FileTest.writable?( @filename )
          raise StandardError, "'#{@filename}' is not writable!"
        end
      else # ensure directory is writable
        dir = File.dirname( @filename )
        if not FileTest.writable?( dir )
          raise StandardError, "'#{dir}' is not writable!"
        end
      end
    end
    
    def create_file
      if ( @create == true ) then
      	@out = File.new(@filename, (@trunc ? "wb" : "ab"))
              @out.sync = Log4rTools.decode_bool(@options, :sync, false)
      	Logger.log_internal {
      	  "FileOutputter '#{@name}' writing to #{@filename}"
      	}
            else
      	Logger.log_internal {
      	  "FileOutputter '#{@name}' called with :create == false, #{@filename}"
      	}
      end
    end

  end

end
