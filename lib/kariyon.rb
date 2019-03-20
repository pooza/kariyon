require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'
require 'ginseng'

module Kariyon
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Deployer
  autoload :Environment
  autoload :Logger
  autoload :Mailer
  autoload :Message
  autoload :Package
  autoload :PeriodicCreator
  autoload :Skeleton
  autoload :Slack
end
