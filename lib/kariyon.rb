require 'active_support'
require 'active_support/core_ext'
require 'active_support/dependencies/autoload'

module Kariyon
  extend ActiveSupport::Autoload

  autoload :Config
  autoload :Deployer
  autoload :Environment
  autoload :Error
  autoload :Feedly
  autoload :Logger
  autoload :Mailer
  autoload :Package
  autoload :PeriodicCreator
  autoload :Skeleton
  autoload :Slack

  autoload_under 'error' do
    autoload :ConfigError
  end
end
