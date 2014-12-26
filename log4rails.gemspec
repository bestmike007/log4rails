# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'log4r/version'

Gem::Specification.new do |gem|
  gem.name = "log4rails"
  gem.version = Log4r::VERSION
  gem.summary = %Q{Log4rails, better log4r for rails}
  gem.description = %Q{Log4rails, better log4r for rails. See http://bestmike007.com/log4rails for more information. Do not use this together with log4r.}
  gem.email = "i@bestmike007.com"
  gem.homepage = "http://bestmike007.com/log4rails"
  gem.authors = ['bestmike007']
  gem.license = 'BSD'
  gem.files = Dir['lib/**/*'] + ['LICENSE.bsd', 'README.md']
  
  gem.required_ruby_version = '>= 1.9.0'
end

