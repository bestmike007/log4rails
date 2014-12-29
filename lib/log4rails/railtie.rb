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

module Log4rails

  class Railtie < Rails::Railtie
    
    config.log4rails = ActiveSupport::OrderedOptions.new
    # default values
    config.log4rails.enabled = false
    config.log4rails.action_mht = 500
    config.log4rails.auto_reload = true

    initializer "log4rails.pre_init", :before => :initialize_logger do |app|
      if app.config.log4rails.enabled
        Log4rails::Railtie.pre_init(app, {:root => Rails.root.to_s, :env => Rails.env}.merge(app.config.log4rails))
      end
    end

    initializer "log4rails.post_init", :after => :initialize_logger do |app|
      if app.config.log4rails.enabled
        Log4rails::Railtie.post_init
      end
    end

    initializer "log4rails.cache_logger", :after => :initialize_cache do |app|
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
    
    class << self
      
      class RailsLoggerSubscriber
        
        def initialize(options)
          @auto_reload = options[:auto_reload]
          @action_mht = options[:action_mht]
          @config_watcher = Log4rConfigWatcher.new
          @config_watcher.check_config
        end
        
        def unsubscribe(component, subscriber)
          events = subscriber.public_methods(false).reject { |method| method.to_s == 'call' }
          events.each do |event|
            ActiveSupport::Notifications.notifier.listeners_for("#{event}.#{component}").each do |listener|
              if listener.instance_variable_get('@delegate') == subscriber
                ActiveSupport::Notifications.unsubscribe listener
              end
            end
          end
        end
        # remove rails default log subscriptions
        # [ActiveRecord::LogSubscriber, ActionController::LogSubscriber, ActionView::LogSubscriber, ActionMailer::LogSubscriber]
        def remove_existing_log_subscriptions
          ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
            case subscriber
            when ActionView::LogSubscriber
              unsubscribe(:action_view, subscriber)
            when ActionController::LogSubscriber
              unsubscribe(:action_controller, subscriber)
            when ActiveRecord::LogSubscriber
              unsubscribe(:active_record, subscriber)
            when ActionMailer::LogSubscriber
              unsubscribe(:action_mailler, subscriber)
            end
          end
        end
        
        def format_duration(start, finish)
          ((finish - start).to_f * 100000).round / 100.0
        end
        
        def config_controller_logger_subscriptions
          controller_logging = ControllerLogging.new(@action_mht)
          ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
            @config_watcher.check_config if @auto_reload
            controller_logging.log_event({ duration: format_duration(start, finish) }.merge(payload))
          end
        end
        
        def config_active_record_logger_subscription
          ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
            @config_watcher.check_config if @auto_reload
            logger = Log4r::Logger["rails::db"] || Log4r::Logger.root
            logger.debug { "(#{format_duration(start, finish)}) #{payload[:sql]}" }
          end
        end
        
      end
      
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
      
      def pre_init(app, opts)
        @initializer = Log4railsRailtieInitializer.new(app, opts)
        @initializer.pre_init
      end
      
      def post_init
        @initializer.post_init
      end
      
    end
    
  end # class Railtie
  
end # module Log4r
