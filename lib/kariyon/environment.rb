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

    def self.uid
      return File.stat(ROOT_DIR).uid
    end

    def self.gid
      return File.stat(ROOT_DIR).gid
    end
  end
end
