module Log4rails

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
  
end