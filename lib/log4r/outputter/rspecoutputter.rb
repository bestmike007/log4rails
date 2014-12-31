# :nodoc:
require "log4r/outputter/outputter"
require 'rspec/expectations'

module Log4r
  
  ##
  # IO Outputter invokes print then flush on the wrapped IO
  # object. If the IO stream dies, IOOutputter sets itself to OFF
  # and the system continues on its merry way.
  #
  # To find out why an IO stream died, create a logger named 'log4r'
  # and look at the output.

  class RspecOutputter < Outputter
    include RSpec::Matchers
    
    def expect_log(str_or_regex, options={})
      @count = options[:times] || 1
      @expecting = str_or_regex
      @got = []
      yield
      if @got.size != @count
        expect {
          raise "\n`#{@expecting.to_s}` should show up #{@count} time(s). Got #{@got.size} times"
        }.not_to raise_error
      end
    ensure
      @expecting = nil
      @count = 0
    end

    #######
    private
    #######
    
    # perform the write
    def write(data)
      return if !@expecting
      data = data[0..-2]
      if @expecting.instance_of? String
        expect(data).to eq(@expecting)
      else
        expect(data).to be =~ @expecting
      end
      @got << data
    end
  end
end
