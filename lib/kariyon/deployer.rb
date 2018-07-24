require 'kariyon/environment'
require 'kariyon/message'
require 'kariyon/logger'
require 'kariyon/slack'
require 'kariyon/mailer'
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
    end

    def clean
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.glob(File.join(dest_root, '*')) do |f|
        begin
          if kariyon?(f) && File.readlink(File.join(f, 'www')).match(ROOT_DIR)
            FileUtils.rm_rf(f)
            @logger.info(Message.new({action: 'delete', file: f}))
          end
        rescue => e
          message = Message.new(e)
          Slack.broadcast(message)
          @logger.error(message)
        end
      end
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def create
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.mkdir(dest, 0o775)
      FileUtils.touch(File.join(dest, '.kariyon'))
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
      File.unlink(root_alias) if File.exist?(root_alias)
      File.symlink(real_root, root_alias)
      message = Message.new({action: 'link', source: real_root, dest: root_alias})
      Slack.broadcast(message)
      @mailer.subject = 'フォルダの切り替え'
      @mailer.body = JSON.pretty_generate(message)
      @mailer.deliver
      @logger.info(message)
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def minc?(path = nil)
      path ||= dest
      return minc3?(path) || minc2?(path)
    end

    def kariyon?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, '.kariyon'))
    end

    private

    def minc3?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, 'webapp/lib/Minc3/Site.class.php'))
    end

    def minc2?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, 'webapp/lib/MincSite.class.php'))
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

    def root_alias
      return File.join(dest, 'www')
    end

    def real_root
      unless @real_root
        if recent
          @real_root = File.join(ROOT_DIR, 'htdocs', recent.strftime('%FT%H:%M'))
        else
          @real_root = File.join(ROOT_DIR, 'htdocs', Time.new.strftime('%FT%H:%M'))
          Dir.mkdir(@real_root)
          File.chown(uid, gid, @real_root)
        end
      end
      return @real_root
    end

    def recent
      return @recent if @recent
      Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          message = Message.new({error: 'invalid folder name', path: f})
          Slack.broadcast(message)
          @logger.error(message)
          @mailer.subject = '不正なフォルダ名'
          @mailer.body = JSON.pretty_generate(message)
          @mailer.deliver
          next
        end
        @recent = time if @recent.nil? || ((@recent < time) && (time <= Time.now))
      end
      return @recent
    end

    def uid
      return File.stat(ROOT_DIR).uid
    end

    def gid
      return File.stat(ROOT_DIR).gid
    end
  end
end
