require 'log4r'
# rails integration
if defined?(Rails::Railtie)
  require 'log4r/railtie'
end
