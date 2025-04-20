module Kariyon
  class PeriodicCreator
    include Singleton

    def initialize
      @logger = Logger.new
    end

    def clean
      Dir.glob(File.join(destroot, '*')) do |path|
        next unless File.symlink?(path)
        next unless File.readlink(path).match?(Environment.dir)
        File.unlink(path)
        @logger.info(action: 'delete', link: path)
      rescue => e
        @logger.error(error: e)
      end
    end

    def create
      File.symlink(src, dest)
      @logger.info(action: 'link', source: src, dest: dest)
    rescue => e
      @logger.error(error: e)
      exit 1
    end

    def src
      return File.join(Environment.dir, 'bin/kariyon.rb')
    end

    def dest
      case Environment.platform
      when :free_bsd, 'FreeBSD'
        return File.join(destroot, "900.kariyon-#{Environment.name}")
      when 'Debian'
        return File.join(destroot, "kariyon-#{Environment.name.tr('.', '-')}")
      end
    end

    def destroot
      case Environment.platform
      when :free_bsd, 'FreeBSD'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
