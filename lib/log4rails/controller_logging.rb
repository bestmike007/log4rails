
module Log4rails
  class ControllerLogging
    
    def initialize(action_mht)
      @action_mht = action_mht
    end
    
    def log_event(payload)
      log_body = lambda {
        "#{payload[:method]} #{payload[:path]} (TIMING[ms]: sum:#{payload[:duration]} db:#{format_time(payload[:db_runtime])} view:#{format_time(payload[:view_runtime])})" + (payload[:exception] ? " EXCEPTION: #{payload[:exception]}" : '')
      }
      write_log(payload[:exception] || payload[:duration] >= @action_mht, log_body, payload[:params])
    end
    
    private
    
    def format_time(time)
      (time * 100).round/100.0 rescue "-"
    end
    
    def write_log(log_with_warn, log_body, params)
      log_with_warn ? logger.warn(&log_body) : logger.info(&log_body)
      params_logger.info { "request params: " + params.to_json }
    end
    
    def logger
      Rails.logger
    end
    
    def params_logger
      Log4r::Logger["rails::params"] || Log4r::Logger.root
    end
    
  end
end