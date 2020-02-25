require 'fileutils'
require 'singleton'

module Kariyon
  class PeriodicCreator
    include Singleton

    def initialize
      @logger = Logger.new
    end

    def clean
      raise 'MINCをアンインストールしてください。' if Deployer.instance.minc?
      Dir.glob(File.join(destroot, '*')) do |f|
        if File.symlink?(f) && File.readlink(f).match(Environment.dir)
          File.unlink(f)
          @logger.info(Message.new({action: 'delete', file: f}))
        end
      rescue => e
        message = Message.new(e)
        Slack.broadcast(message)
        @logger.error(message)
      end
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def create
      raise 'MINCをアンインストールしてください。' if Deployer.instance.minc?
      File.symlink(src, dest)
      @logger.info(Message.new({action: 'link', source: src, dest: dest}))
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    private

    def src
      return File.join(Environment.dir, 'bin/kariyon.rb')
    end

    def dest
      case Environment.platform
      when 'FreeBSD', 'Darwin'
        return File.join(destroot, "900.kariyon-#{Environment.name}")
      when 'Debian'
        return File.join(destroot, "kariyon-#{Environment.name.tr('.', '-')}")
      end
    end

    def destroot
      case Environment.platform
      when 'FreeBSD', 'Darwin'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
