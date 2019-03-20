require 'singleton'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    include Singleton

    def initialize
      @logger = Logger.new
      @mailer = Mailer.new
      @skeleton = Skeleton.new
    end

    def clean
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.glob(File.join(dest_root, '*')) do |f|
        next unless kariyon?(f)
        next unless File.readlink(File.join(f, 'www')).match(Environment.dir)
        FileUtils.rm_rf(f)
        @logger.info(Message.new({action: 'delete', file: f}))
      rescue => e
        message = Message.new(e)
        Slack.broadcast(message)
        @logger.error(message)
      end
    end

    def create
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.mkdir(dest, 0o775)
      File.chown(Environment.uid, Environment.gid, dest)
      FileUtils.touch(dot_kariyon)
      File.chown(Environment.uid, Environment.gid, dot_kariyon)
      @logger.info(Message.new({action: 'create', file: dest}))
      update
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def update
      return if File.exist?(root_alias) && (File.readlink(root_alias) == real_root)
      begin
        File.symlink(real_root, root_alias)
        File.chown(Environment.uid, Environment.gid, root_alias)
      rescue Errno::EEXIST
        File.unlink(root_alias)
        retry
      end
      message = Message.new({action: 'link', source: real_root, dest: root_alias})
      Slack.broadcast(message)
      @mailer.deliver('フォルダの切り替え', message)
      @logger.info(message)
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def minc?(parent = nil)
      parent ||= dest
      return minc3?(parent) || minc2?(parent)
    end

    def kariyon?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, '.kariyon'))
    end

    private

    def minc3?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, 'webapp/lib/Minc3/Site.class.php'))
    end

    def minc2?(parent = nil)
      parent ||= dest
      return File.exist?(File.join(parent, 'webapp/lib/MincSite.class.php'))
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
          @real_root = File.join(Environment.dir, 'htdocs', recent.strftime('%FT%H:%M'))
        else
          @real_root = File.join(Environment.dir, 'htdocs', Time.new.strftime('%FT%H:%M'))
          Dir.mkdir(@real_root)
          File.chown(Environment.uid, Environment.gid, @real_root)
        end
      end
      return @real_root
    end

    def recent
      return @recent if @recent
      Dir.glob(File.join(Environment.dir, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        @skeleton.copy_to(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          message = Message.new({error: 'invalid folder name', path: f})
          Slack.broadcast(message)
          @logger.error(message)
          @mailer.deliver('不正なフォルダ名', message)
          next
        end
        @recent = time if @recent.nil? || ((@recent < time) && (time <= Time.now))
      end
      return @recent
    end
  end
end
