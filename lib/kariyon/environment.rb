module Kariyon
  class Environment
    def self.name
      return File.basename(ROOT_DIR)
    end

    def self.platform
      return 'Debian' if File.executable?('/usr/bin/apt-get')
      return `uname`.chomp
    end

    def self.cron?
      return ENV.member?('CRON') && (ENV['CRON'] != '')
    end
  end
end
