# :nodoc:
# Version:: $Id$
# Author:: Mike Ho <i(at)bestmike007.com>
# How to configure log4r for rails in application.rb:
# config.log4rails.<option> = <value>
# config.log4rails.enabled = true # enable log4r integration
# config.log4rails.action_mht = 500 # maximum action handling time to log with level INFO, default: 500ms.
# config.log4rails.auto_reload = true # auto-reload log4r configuration file from config/log4r.yaml (or config/log4r-production.yaml in production environment)

require 'rails'
require 'log4rails/log4r_config_watcher'
require 'log4rails/controller_logging'
require 'log4rails/rails_logger_subscriber'

module Log4rails

  class Railtie < Rails::Railtie
    
    class << self
      
      class Log4railsRailtieInitializer
        
        def initialize(app, options)
          @app = app
          @options = options
        end
        
        public
        
        def pre_init
          # silence default rails logger
          @app.config.log_level = :unknown
          # define global logger
          setup_logger Object, "root"
          # define rails controller logger names
          setup_logger ActionController::Base, "rails::controllers"
          setup_logger ActiveRecord::Base, "rails::models"
          setup_logger ActionMailer::Base, "rails::mailers"
          
          subscriber = RailsLoggerSubscriber.new(@options)
          subscriber.remove_existing_log_subscriptions
          subscriber.config_controller_logger_subscriptions
          subscriber.config_active_record_logger_subscription
        end
        
        def post_init
          setup_logger Rails, "rails"
          # disable rack development output, e.g. Started GET "/session/new" for 127.0.0.1 at 2012-09-26 14:51:42 -0700
          if Rails.const_defined?(:Rack) && Rails::Rack.const_defined?(:Logger)
            setup_logger Rails::Rack::Logger, "root"
          end
          # override DebugExceptions output
          ActionDispatch::DebugExceptions.module_eval %-
            def log_error(env, wrapper)
              logger = Rails.logger
              exception = wrapper.exception
              # trace = wrapper.application_trace
              # trace = wrapper.framework_trace if trace.empty?
              logger.info "ActionDispatch Exception: \#{exception.class} (\#{exception.message})"
            end
            private :log_error
          -
        end
        
        # convenient method to setup logger for class and descendants.
        def setup_logger(clazz, logger_name)
          clazz.module_eval %(
            class << self
              custom_logger = nil
              define_method :logger do
                custom_logger || Log4r::Logger['#{logger_name}'] || Log4r::Logger.root
              end
              define_method :logger= do |l|
                (l || custom_logger).debug "Log4rails is preventing set of logger. Use #custom_logger= if you really want it set."
              end
              define_method :custom_logger= do |l|
                custom_logger = l
              end
            end
            
            def logger
              #{clazz.name}.logger
            end
          )
        end
        
      end
      
      def before_init
        config.log4rails = ActiveSupport::OrderedOptions.new
        # default values
        config.log4rails.enabled = false
        config.log4rails.action_mht = 500
        config.log4rails.auto_reload = true
      end
      
      def pre_init(app)
        if app.config.log4rails.enabled
          opts = {:root => Rails.root.to_s, :env => Rails.env}.merge(app.config.log4rails)
          @initializer = Log4railsRailtieInitializer.new(app, opts)
          @initializer.pre_init
        end
      end
      
      def post_init(app)
        if app.config.log4rails.enabled
          @initializer.post_init
        end
      end
      
      def init_cache_logger(app)
        if app.config.log4rails.enabled
          class << Rails.cache
            def logger
              Log4r::Logger['rails::cache'] || Log4r::Logger.root
            end
            def logger=(l)
              (l || logger).debug "Log4r is preventing set of logger for cache."
            end
          end
        end
      end
      
    end # class << Railtie
    
    InitializerOptions = {
      pre_init: { before: :initialize_logger },
      post_init: { after: :initialize_logger },
      init_cache_logger: { after: :initialize_cache }
    }
    
    before_init
    
    InitializerOptions.each { |k, v| initializer "log4rails.#{k}", v, &method(k) }
    
  end # class Railtie
  
end # module Log4r
