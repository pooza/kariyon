module Kariyon
  class Logger < Ginseng::Logger
    include Package

    # ginseng-upstream: hold — 端末にも出したい利用側が 2 つ目に現れたら（rake から人が流す道具なので syslog と併せて出している）
    def info(message)
      puts message.deep_stringify_keys.to_yaml
      super
    end

    # ginseng-upstream: hold — 端末にも出したい利用側が 2 つ目に現れたら（info と同じ）
    def error(message)
      warn message.deep_stringify_keys.to_yaml
      super
    end
  end
end
