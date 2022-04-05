module Kariyon
  class Deployer
    include Singleton
    TIME_FORMAT = '%Y%m%d%H%M'.freeze

    def initialize
      @logger = Logger.new
      @mailer = Ginseng::Mailer.new
      @skeleton = Skeleton.new
      @config = Config.instance
    end

    def clean
      Dir.glob(File.join(dest_root, '*')) do |f|
        next unless kariyon?(f)
        next unless File.readlink(File.join(f, 'www')).match?(Environment.dir)
        #FileUtils.rm_rf(f)
        @logger.info(action: 'delete', file: f)
      rescue => e
        warn e.message
        exit 1
      end
    end

    def create
      #Dir.mkdir(dest, 0o775)
      #File.chown(Environment.uid, Environment.gid, dest)
      #FileUtils.touch(dot_kariyon)
      #File.chown(Environment.uid, Environment.gid, dot_kariyon)
      @logger.info(action: 'create', file: dest)
      #update
    rescue => e
      warn e.message
      exit 1
    end

    def update
      return if File.exist?(root_alias) && (File.readlink(root_alias) == real_root)
      begin
        File.symlink(real_root, root_alias)
        File.lchown(Environment.uid, Environment.gid, root_alias)
        @skeleton.copy_to(real_root)
      rescue Errno::EEXIST
        File.unlink(root_alias)
        retry
      end
      message = Message.new(action: 'link', source: real_root, dest: root_alias)
      @mailer.deliver('フォルダの切り替え', message)
      @logger.info(message)
    rescue => e
      @logger.error(error: e)
      exit 1
    end

    def mix_mode?
      return @config['/mix'] == true
    end

    def minc?(parent = nil)
      parent ||= dest
      return minc3?(parent) || minc2?(parent)
    end

    def kariyon?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, '.kariyon'))
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
      warn e.message
      exit 1
    end

    def minc3?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, 'webapp/lib/Minc3/Site.class.php'))
    end

    def minc2?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, 'webapp/lib/MincSite.class.php'))
    end

    private

    def dest_root
      case Environment.platform
      when 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        raise "#{Environment.platform}は未対応です。"
      end
    end

    def dest
      return File.join(dest_root, Environment.name)
    end

    def dot_kariyon(parent = nil)
      parent ||= dest
      return File.join(parent, '.kariyon')
    end

    def root_alias(parent = nil)
      parent ||= dest
      return File.join(parent, 'www')
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
          message = Message.new(error: 'invalid folder name', path: d)
          @logger.error(message)
          @mailer.deliver('不正なフォルダ名', message)
        end
        dirs = dirs.map {|d| Time.parse(File.basename(d))}
        @recent = dirs.select {|d| d <= Time.now}.max
      end
      return @recent
    end
  end
end
