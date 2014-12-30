require 'log4r/yamlconfigurator'

module Log4rails
  
  class Log4rConfigWatcher
    
    def initialize
      @config_time = Time.new 0
      @config_next_check = Time.now
    end
    # load or reload config from RAILS_ROOT/config/log4r.yaml or RAILS_ROOT/config/log4r-production.yaml
    def check_config
      # auto reload config every 30 seconds.
      return unless check_again?
      detect_existing_config_path
      return if File.mtime(@config_path) == @config_time
      Log4r::YamlConfigurator.load_yaml_file @config_path
      @config_time = File.mtime(@config_path)
    rescue Log4r::ConfigError => e
      puts "Log4r Error: Unable to load config #{@config_path}, error: #{e}."
    end
    
    private
    
    def default_config_path
      File.join File.dirname(__FILE__), 'log4r-rails.yaml'
    end
    
    def detect_existing_config_path
      @config_path = get_existing_config_path
    end
    
    def get_existing_config_path
      if Rails.env == 'production'
        production_config_path = File.join Rails.root, "config", "log4r-production.yaml"
        return production_config_path if File.file?(production_config_path)
      end
      development_config_path = File.join Rails.root, "config", "log4r.yaml"
      File.file?(development_config_path) ? development_config_path : default_config_path
    end
    
    def check_again?
      return false if Time.now < @config_next_check
      @config_next_check = Time.now + 30
      return true
    end
    
  end
  
end