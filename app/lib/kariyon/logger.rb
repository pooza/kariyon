module Kariyon
  class Logger < Ginseng::Logger
    include Package

    def info(message)
      puts message.deep_stringify_keys.to_yaml
      super
    end

    def error(message)
      warn message.deep_stringify_keys.to_yaml
      super
    end
  end
end
