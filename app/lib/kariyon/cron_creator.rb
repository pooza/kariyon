module Kariyon
  # 切り替えを毎分の cron で単独で動かす（#306）。
  # periodic の frequently（多くの機で 5 分ごと）の中だと、ほかの処理が長引いたときに
  # 回ごと飛ばされて切り替えが遅れるので、cron.d に 1 行を置いて外へ出す。
  class CronCreator
    include Singleton

    def initialize
      @logger = Logger.new
    end

    def clean
      return unless File.exist?(path)
      File.unlink(path)
      @logger.info(action: 'delete', file: path)
    rescue => e
      @logger.error(error: e)
    end

    def create
      File.write(path, contents)
      File.chmod(0o644, path)
      @logger.info(action: 'create', file: path)
    rescue => e
      @logger.error(error: e)
      exit 1
    end

    def contents
      return <<~CRON
        # kariyon #{Environment.name}（rake kariyon:cron:init が置いた。手で直さない）
        SHELL=/bin/sh
        PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
        * * * * * root #{src} > /dev/null
      CRON
    end

    def src
      return File.join(Environment.dir, 'bin/kariyon.rb')
    end

    # Debian の cron は、名前に「.」を含むファイルを読まない。
    def path
      return File.join(destroot, "kariyon-#{Environment.name.tr('.', '-')}")
    end

    def destroot
      case Environment.platform
      when :free_bsd, 'FreeBSD'
        return '/usr/local/etc/cron.d'
      when 'Debian'
        return '/etc/cron.d'
      else
        raise "#{Environment.platform}は未対応です。"
      end
    end
  end
end
