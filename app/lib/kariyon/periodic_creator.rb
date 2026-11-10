module Kariyon
  # 古い版が置いた periodic のリンクを消す（切り替えは毎分の cron へ移した・#306）。
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
