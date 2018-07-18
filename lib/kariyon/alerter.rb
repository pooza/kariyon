require 'kariyon/logger'
require 'kariyon/slack'
require 'kariyon/environment'

module Kariyon
  class Alerter
    def self.log(message)
      Logger.new.info(create_full_message(message))
    end

    def self.alert(message)
      full = create_full_message(message)
      Logger.new.error(full)
      Slack.broadcast(full)
    end

    def self.create_full_message(message)
      full = {environment: Environment.name}
      full.update(message)
      return full
    end
  end
end
