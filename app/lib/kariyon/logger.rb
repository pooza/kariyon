module Kariyon
  class Logger < Ginseng::Logger
    include Package

    def info(message)
      puts message.to_json
      super
    end
  end
end
