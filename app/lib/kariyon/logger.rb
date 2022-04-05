module Kariyon
  class Logger < Ginseng::Logger
    include Package

    def info(message)
      puts message
      super
    end

    def error(message)
      warn message
      super
    end
  end
end
