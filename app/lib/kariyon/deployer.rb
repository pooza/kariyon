module Kariyon
  class Deployer
    include Singleton

    TIME_FORMAT = '%Y%m%d%H%M'.freeze

    def initialize
      @logger = Logger.new
      @skeleton = Skeleton.new
      @config = Config.instance
    end

    def clean
      if mix_mode?
        if File.exist?(dot_kariyon)
          File.unlink(dot_kariyon)
          @logger.info(action: 'delete', file: dot_kariyon)
        end
        clear_aliases
      else
        FileUtils.rm_rf(dest)
        @logger.info(action: 'delete', dir: dest)
      end
    end

    def create
      unless mix_mode?
        Dir.mkdir(dest, 0o775)
        File.chown(Environment.uid, Environment.gid, dest)
        @logger.info(action: 'create', file: dest)
      end
      update
    rescue => e
      @logger.info(error: e)
      exit 1
    end

    def update
      @logger.info(action: 'start')
      unless File.exist?(dot_kariyon)
        FileUtils.touch(dot_kariyon)
        File.chown(Environment.uid, Environment.gid, dot_kariyon)
        @logger.info(action: 'touch', file: dot_kariyon)
      end
      clear_aliases
      if mix_mode?
        update_aliases
      else
        update_root_alias
      end
      notify_switch
      @logger.info(action: 'end')
    end

    def clear_aliases
      Dir.glob(File.join(dest, '*')).select {|p| File.symlink?(p)}.each do |path|
        next unless File.readlink(path).match?(Environment.dir)
        File.unlink(path)
        @logger.info(action: 'delete', link: path)
      end
      return unless File.exist?(root_alias)
      File.unlink(root_alias)
      @logger.info(action: 'delete', link: root_alias)
    end

    def update_aliases
      Dir.glob(File.join(real_root, '*')).each do |path|
        dest_alias = File.join(dest, File.basename(path))
        File.symlink(path, dest_alias)
        File.lchown(Environment.uid, Environment.gid, dest_alias)
        @logger.info(action: 'link', source: path, dest: dest_alias)
      rescue => e
        @logger.error(error: e)
      end
    end

    def update_root_alias
      File.symlink(real_root, root_alias)
      File.lchown(Environment.uid, Environment.gid, root_alias)
      @logger.info(action: 'link', source: real_root, dest: root_alias)
      @skeleton.copy_to(real_root)
    rescue Errno::EEXIST
      File.unlink(root_alias)
      retry
    end

    def mix_mode?
      return @config['/mix'] == true
    end

    def kariyon?(parent = nil)
      parent ||= dest
      return File.exist?(dot_kariyon(parent))
    end

    # 証明書の確認用のディレクトリ。設定（well_known_dir）にあればそれを使い、
    # 無ければ公開先から、kariyonでもリンクでもないディレクトリを1つ探す。
    def well_known_dir
      return configured_well_known_dir if configured_well_known_dir
      dirs = Dir.glob(File.join(dest_root, '*')).select {|f| File.directory?(f)}
      dirs.reject! {|f| File.symlink?(f)}
      dirs.reject! {|f| kariyon?(f)}
      raise "'#{dest_root}'内に対象ディレクトリが複数あります。" if 1 < dirs.count
      raise "'#{dest_root}'内に対象ディレクトリがありません。" if dirs.none?
      dir = File.join(dirs.first, 'www/.well-known')
      raise "'#{dir}'がありません。" unless File.exist?(dir)
      return dir
    rescue => e
      @logger.error(error: e)
      exit 1
    end

    def configured_well_known_dir
      dir = @config['/well_known_dir']
      raise "'#{dir}'がありません。" unless File.exist?(dir)
      return dir
    rescue Ginseng::ConfigError
      return nil
    end

    def dest_root
      case Environment.platform
      when :free_bsd, 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        raise "#{Environment.platform}は未対応です。"
      end
    end

    def dest
      return File.join(dest_root, Environment.name, 'www') if mix_mode?
      return File.join(dest_root, Environment.name)
    end

    def dot_kariyon(parent = nil)
      parent ||= dest
      return File.join(parent, '.kariyon')
    end

    def session_path
      return File.join('/tmp', "#{Package.name}-#{Environment.name}")
    end

    def session
      return {} unless File.readable?(session_path)
      return JSON.parse(File.read(session_path))
    end

    # 切り替えたと認めてよい遅れ。これを超えたら error で残す（#306）。
    DELAY_LIMIT = 60

    def session=(values)
      prev = session['recent']
      File.write(session_path, values.to_json)
      @switched = !prev.nil? && !session['recent'].nil? && prev < session['recent']
    rescue => e
      @logger.error(error: e)
    end

    # 公開のリンクを張り替えたあとに呼ぶ。遅れには張り替えまでの時間を含め、通知の待ちは含めない。
    def notify_switch
      return unless @switched
      log_delay(@recent)
      mailer = Mailer.new
      mailer.subject = "#{Environment.name} フォルダの切り替え"
      mailer.body = "#{real_root} に切り替えました。"
      mailer.deliver
    rescue => e
      @logger.error(error: e)
    end

    # 予定の時刻（フォルダ名）から、実際に切り替えた時刻までの遅れを残す。
    def log_delay(scheduled, now = Time.now)
      delay = (now - scheduled).round
      entry = {action: 'switch', scheduled: scheduled.to_s, actual: now.to_s, delay:}
      return @logger.info(entry) if delay <= DELAY_LIMIT
      @logger.error(entry.merge(error: "切り替えが#{delay}秒遅れました。"))
    end

    def root_alias
      return File.join(dest, 'www')
    end

    def real_root
      unless @real_root
        if recent
          @real_root = File.join(Environment.dir, 'htdocs', recent.strftime(TIME_FORMAT))
        else
          @real_root = File.join(Environment.dir, 'htdocs', Time.now.strftime(TIME_FORMAT))
          Dir.mkdir(@real_root)
          File.chown(Environment.uid, Environment.gid, @real_root)
        end
      end
      return @real_root
    end

    def recent
      unless @recent
        dirs = Dir.glob(File.join(Environment.dir, 'htdocs/*')).select {|d| File.directory?(d)}
        dirs.clone.each do |d|
          Time.parse(File.basename(d))
        rescue ArgumentError
          dirs.delete(d)
          @logger.error(error: 'invalid folder name', path: d)
        end
        dirs = dirs.map {|d| Time.parse(File.basename(d))}
        @recent = dirs.select {|d| d <= Time.now}.max
        self.session = {recent: @recent}
      end
      return @recent
    end
  end
end
