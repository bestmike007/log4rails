require "rspec_helper"

RSpec.describe "Log4r" do
  
  before(:each) {
    reload_log4r
    Log4r::Logger.root
  }
  
  it "tests formatter with MDC" do
    l = Log4r::Logger.new 'test::this::that::other'
    l.trace = true
    o = Log4r::RspecOutputter.new 'testy'
    l.add o
    f = Log4r::PatternFormatter.new :pattern=> "%d %6l [%C]%c {%X{user}} %% %-40.30M"
                             #:date_pattern=> "%Y"
                             #:date_method => :usec
    o.formatter = f

    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {} % no user\s+$/) {
      l.info "no user"
    }
    Log4r::MDC.put("user","bestmike007")
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {bestmike007} % user bestmike007\s+$/) {
      l.info "user bestmike007"
    }
  end
  
  it "tests basic pattern formatter functions" do
    l = Log4r::Logger.new 'test::this::that'
    l.trace = true
    o = Log4r::RspecOutputter.new 'test'
    l.add o
    expect {
      f = Log4r::PatternFormatter.new :pattern=> "'%t' T-'%T' %d %6l [%C]%c %% %-40.30M"
                               #:date_pattern=> "%Y"
                               #:date_method => :usec
      o.formatter = f
      o.expect_log(/^.+pattern_formatter_spec.+ T-'pattern_formatter_spec\.rb:\d+:in.+ \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}  DEBUG \[test::this::that\]that % And this\s+$/) {
        l.debug "And this"
      }
      o.expect_log(/^.+pattern_formatter_spec.+ T-'pattern_formatter_spec\.rb:\d+:in.+ \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that\]that % How's this\s+$/) {
        l.info "How's this"
      }
      o.expect_log(/^.+pattern_formatter_spec.+ T-'pattern_formatter_spec\.rb:\d+:in.+ \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}  ERROR \[test::this::that\]that % and a really freaking huge lin\s*$/) {
        l.error "and a really freaking huge line which we hope will be trimmed?"
      }
      e = ArgumentError.new("something barfed")
      e.set_backtrace Array.new(5, "trace junk at thisfile.rb 154")
      o.expect_log(/^.+pattern_formatter_spec.+ T-'pattern_formatter_spec\.rb:\d+:in.+ \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}  FATAL \[test::this::that\]that % Caught ArgumentError: somethin\s*$/) {
        l.fatal e
      }
      o.expect_log(/^.+pattern_formatter_spec.+ T-'pattern_formatter_spec\.rb:\d+:in.+ \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that\]that % Array: \[1, 3, 5\]\s+$/) {
        l.info [1, 3, 5]
      }
    }.not_to raise_error
  end
  
  it "tests formatter with NDC" do
    l = Log4r::Logger.new 'test::this::that::other'
    l.trace = true
    o = Log4r::RspecOutputter.new 'testy'
    l.add o
    f = Log4r::PatternFormatter.new :pattern=> "%d %6l [%C]%c {%x} %% %-40.30M"
                             #:date_pattern=> "%Y"
                             #:date_method => :usec
    o.formatter = f
    
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {} % no NDC\s+$/) {
      l.info "no NDC"
    }
    Log4r::NDC.push("start")
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {start} % start NDC\s+$/) {
      l.info "start NDC"
    }
    Log4r::NDC.push("finish")
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {start finish} % start finish NDC\s+$/) {
      l.info "start finish NDC"
    }
    Log4r::NDC.pop()
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {start} % start NDC\s+$/) {
      l.info "start NDC"
    }
    Log4r::NDC.remove()
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {} % no NDC\s+$/) {
      l.info "no NDC"
    }
  end
  
  it "tests formatter with GDC" do
    l = Log4r::Logger.new 'test::this::that::other'
    l.trace = true
    o = Log4r::RspecOutputter.new 'testy'
    l.add o
    f = Log4r::PatternFormatter.new :pattern=> "%d %6l [%C]%c {%g} %% %-40.30M"
                             #:date_pattern=> "%Y"
                             #:date_method => :usec
    o.formatter = f

    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {.+rspec} % GDC default\s+$/) {
      l.info "GDC default"
    }
    Log4r::GDC.set("non-default")
    o.expect_log(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}   INFO \[test::this::that::other\]other {non-default} % GDC non-default\s+$/) {
      l.info "GDC non-default"
    }
  end
end
