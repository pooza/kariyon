module Kariyon
  class Logger < Ginseng::Logger
    include Package

    def info(message)
      puts message.to_yaml
      super
    end

    def error(message)
      warn message.to_yaml
      super
    end
  end
end
