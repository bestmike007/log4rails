# :include: ../rdoc/emailoutputter

require 'log4r/outputter/outputter'
require 'log4r/staticlogger'
require 'net/smtp'

module Log4r

  class EmailOutputter < Outputter
    attr_reader :server, :port, :domain, :acct, :authtype, :subject, :tls

    def initialize(_name, hash={})
      super(_name, hash)
      validate(hash)
      @buff = []
      begin 
      	Logger.log_internal {
      	  "EmailOutputter '#{@name}' running SMTP client on #{@server}:#{@port}"
      	}
      rescue Exception => e
        verbose_error(e) {
	        "EmailOutputter '#{@name}' failed to start SMTP client!"
        }
      	raise
      end
    end

    # send out an email with the current buffer
    def flush
      synch { send_mail }
      Logger.log_internal {"Flushed EmailOutputter '#{@name}'"}
    end

    private

    def validate(hash)
      @buffsize = (hash[:buffsize] or hash['buffsize'] or 100).to_i
      @formatfirst = Log4rTools.decode_bool(hash, :formatfirst, false)
      decode_immediate_at(hash)
      validate_smtp_params(hash)
    end

    def decode_immediate_at(hash)
      @immediate = Hash.new
      _at = (hash[:immediate_at] or hash['immediate_at'])
      return if _at.nil?
      Log4rTools.comma_split(_at).each {|lname|
      	level = LNAMES.index(lname)
      	if level.nil?
      	  Logger.log_internal(-2) do
      	    "EmailOutputter: skipping bad immediate_at level name '#{lname}'"
      	  end
      	  next
      	end
      	@immediate[level] = true
      }
    end
    
    ParameterParsers = {
      from: nil,
      to: { default: "", formatter: lambda { |v| Log4rTools.comma_split(v) } },
      server: { default: "localhost" },
      port: { default: 25, formatter: lambda { |v| v.to_i } },
      domain: { default: ENV['HOSTNAME'] },
      acct: nil,
      passwd: nil,
      authtype: { default: :cram_md5, formatter: lambda { |v| v.to_s.to_sym } },
      subject: { default: "Message of #{$0}" },
      tls: nil
    }

    def validate_smtp_params(hash)
      ParameterParsers.each { |k, v|
        v ||= {}
        value = hash[k] || hash[k.to_s]
        value ||= v[:default]
        value = v[:formatter].call(value) if v[:formatter]
        instance_variable_set "@#{k}".to_sym, value
      }
      # @from = (hash[:from] or hash['from'])
      # _to = (hash[:to] or hash['to'] or "")
      # @to = Log4rTools.comma_split(_to) 
      # @server = (hash[:server] or hash['server'] or 'localhost')
      # @port = (hash[:port] or hash['port'] or 25).to_i
      # @domain = (hash[:domain] or hash['domain'] or ENV['HOSTNAME'])
      # @acct = (hash[:acct] or hash['acct'])
      # @passwd = (hash[:passwd] or hash['passwd'])
      # @authtype = (hash[:authtype] or hash['authtype'] or :cram_md5).to_s.to_sym
      # @subject = (hash[:subject] or hash['subject'] or "Message of #{$0}")
      # @tls = (hash[:tls] or hash['tls'] or nil)
      raise ArgumentError, "Must specify from address" if @from.nil?
      raise ArgumentError, "Must specify recepients" if @to.empty?
      @params = [@server, @port, @domain, @acct, @passwd, @authtype]
    end

    def canonical_log(event)
      synch {
	      @buff.push @formatfirst ? @formatter.format(event) : event
        send_mail if @buff.size >= @buffsize or @immediate[event.level]
      }
    end

    def send_mail
      msg = (@formatfirst ? @buff : @buff.collect{|e| @formatter.format e}).join
      ### build a mail header for RFC 822
      rfc822msg = build_rfc822_msg(msg)
      ### send email
      begin
	      smtp = Net::SMTP.new( @server, @port )
        enable_starttls(smtp) if ( @tls )
        smtp.start(@domain, @acct, @passwd, @authtype) do |s|
	        s.send_message(rfc822msg, @from, @to)
        end
      rescue Exception => e
        verbose_error(e) {
	        "EmailOutputter '#{@name}' couldn't send email!"
        }
        raise
      ensure @buff.clear
      end # begin
    end # def send_mail
    
    private
    
    def verbose_error(e, &block)
      Logger.log_internal(-2, &block)
      Logger.log_internal {e}
      self.level = OFF
    end
    
    def build_rfc822_msg(msg)
      [
        "From: #{@from}",
        "To: #{@to}",
        "Subject: #{@subject}",
        "Date: #{ Time.now.strftime("%a, %d %b %Y %H:%M:%S %z %Z") }",
        "Message-Id: <#{"%.8f" % Time.now.to_f}@#{@domain}>",
        "",
        msg
      ].join("\n")
    end
    
    def enable_starttls(smtp)
  	  # >1.8.7 has smtp_tls built in, 1.8.6 requires smtp_tls
  	  if RUBY_VERSION < "1.8.7" then
  	    begin
  	      require 'rubygems'
  	      require 'smtp_tls'
  	      smtp.enable_starttls if smtp.respond_to?(:enable_starttls)
  	    rescue LoadError
  	      Logger.log_internal(-2) {
  	        "EmailOutputter '#{@name}' unable to load smtp_tls, needed to support TLS on Ruby versions < 1.8.7"
  	      }
  	      raise
  	    end
  	  else # RUBY_VERSION >= 1.8.7
  	    smtp.enable_starttls_auto if smtp.respond_to?(:enable_starttls_auto)
  	  end
    end
  end # class EmailOutputter
end # module Log4r
