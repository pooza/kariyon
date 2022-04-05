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
        Dir.glob(File.join(dest, '*')).select {|p| File.symlink?(p)}.each do |path|
          next unless File.readlink(f).match?(Environment.dir)
          File.unlink(path)
          @logger.info(action: 'delete', link: path)
        end
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
        update_root_alias
      end
      touch_dot_kariyon
    rescue => e
      @logger.info(error: e)
      exit 1
    end

    def update
      if mix_mode?
        update_aliases
      else
        update_root_alias
      end
    end

    def touch_dot_kariyon
      return if File.exist?(dot_kariyon)
      FileUtils.touch(dot_kariyon)
      File.chown(Environment.uid, Environment.gid, dot_kariyon)
      @logger.info(action: 'touch', file: dot_kariyon)
    end

    def update_aliases
      touch_dot_kariyon
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
      return if File.exist?(root_alias) && (File.readlink(root_alias) == real_root)
      begin
        File.symlink(real_root, root_alias)
        File.lchown(Environment.uid, Environment.gid, root_alias)
        @logger.info(action: 'link', source: real_root, dest: root_alias)
        @skeleton.copy_to(real_root)
      rescue Errno::EEXIST
        File.unlink(root_alias)
        retry
      end
    rescue => e
      @logger.error(error: e)
      exit 1
    end

    def mix_mode?
      return @config['/mix'] == true
    end

    def kariyon?(parent = nil)
      parent ||= dest
      return File.exist?(dot_kariyon(parent))
    end

    def well_known_dir
      dirs = Dir.glob(File.join(dest_root, '*'))
      dirs.reject! {|f| File.symlink?(f)}
      dirs.reject! {|f| kariyon?(f)}
      raise "'#{dest_root}'内に対象ディレクトリが複数あります。" if 1 < dirs.count
      raise "'#{dest_root}'内に対象ディレクトリがありません。" if dirs.count.zero?
      dir = File.join(dirs.first, 'www/.well-known')
      raise "'#{dir}'がありません。" unless File.exist?(dir)
      return dir
    rescue => e
      logger.error(error: e)
      exit 1
    end

    def dest_root
      case Environment.platform
      when 'FreeBSD'
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

    def root_alias
      return File.join(dest, 'www')
    end

    def real_root
      unless @real_root
        if recent
          @real_root = File.join(Environment.dir, 'htdocs', recent.strftime(TIME_FORMAT))
        else
          @real_root = File.join(Environment.dir, 'htdocs', Time.new.strftime(TIME_FORMAT))
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
      end
      return @recent
    end
  end
end
