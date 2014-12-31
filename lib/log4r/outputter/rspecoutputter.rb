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
      @got = []
    end
    
    def expect_logs(*arr)
      @expecting = arr
      yield
      if @expecting.size > 0
        expect(nil).to eq(@expecting[0])
      end
    ensure
      @expecting = nil
      @count = 0
      @got = []
    end
    
    def dump_logs
      @expecting = :all
      @count = 0
      @got = []
      yield
      @got
    ensure
      @expecting = nil
      @count = 0
      @got = []
    end

    #######
    private
    #######
    
    # perform the write
    def write(data)
      return if !@expecting
      data = data[0..-2]
      m = @expecting.instance_of?(Array) ? @expecting.shift : @expecting
      if m.instance_of? String
        expect(data).to eq(m)
      elsif m.instance_of? Regexp
        expect(data).to be =~ m
      elsif m != :all
        puts data
      end
      @got << data unless @expecting.instance_of? Array
    end
  end
end
