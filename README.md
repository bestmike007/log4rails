[![Gem Version](https://badge.fury.io/rb/log4rails.svg)](http://badge.fury.io/rb/log4rails)
[![Code Climate](https://codeclimate.com/github/bestmike007/log4rails/badges/gpa.svg)](https://codeclimate.com/github/bestmike007/log4rails)
[![Test Coverage](https://codeclimate.com/github/bestmike007/log4rails/badges/coverage.svg)](https://codeclimate.com/github/bestmike007/log4rails)

Log4r - A flexible logging library for Ruby

Log4rails - A better log4r especially for rails

```
gem install log4rails
```

DO NOT USE THIS TOGETHER WITH `log4r`!

``` ruby
config.log4rails.<option> = <value>
# enable log4rails integration
config.log4rails.enabled = true
# maximum action handling time to log with level INFO, default: 500ms.
config.log4rails.action_mht = 500
# auto-reload log4r configuration file from config/log4r.yaml (or config/log4r-production.yaml in production environment)
config.log4rails.auto_reload = true
```

## Why this fork

Log4r seems not to be actively maintained. And also I need these features:

+ Integrate with the latest rails
+ Reload the configuration file in production mode in order to switch ON/OFF logs
+ Better RollingFileOutputter, etc.

## TODO

+ Better integrate with rails
+ Write more tests
+ Document is important, especially since rubyforge is dead
+ Refactor
+ Fix issues for general usage
+ Improve extensibility

You're welcome to contribute!