require 'kariyon/environment'
require 'kariyon/message'
require 'kariyon/logger'
require 'kariyon/slack'
require 'singleton'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    include Singleton

    def initialize
      @logger = Logger.new
    end

    def clean
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.glob(File.join(destroot, '*')) do |f|
        begin
          if kariyon?(f) && File.readlink(File.join(f, 'www')).match(ROOT_DIR)
            FileUtils.rm_rf(f)
            @logger.info(Message.new({
              action: 'delete',
              file: f,
            }))
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
      @logger.info(Message.new({
        action: 'create',
        file: dest,
      }))
      update
    rescue => e
      message = Message.new(e)
      Slack.broadcast(message)
      @logger.error(message)
      exit 1
    end

    def update
      link = File.join(dest, 'www')
      root = read_root_path
      return if File.exist?(link) && (File.readlink(link) == root)
      File.unlink(link) if File.exist?(link)
      File.symlink(root, link)
      message = Message.new({
        action: 'link',
        source: root,
        dest: link,
      })
      Slack.broadcast(message)
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

    def destroot
      case Environment.platform
      when 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        raise "#{Environment.platform}は未対応です。"
      end
    end

    def dest
      return File.join(destroot, Environment.name)
    end

    def read_root_path
      current = nil
      Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          message = Message.new({
            error: 'invalid folder name',
            name: File.basename(f),
          })
          Slack.broadcast(message)
          @logger.error(message)
          next
        end
        current = time if current.nil? || ((current < time) && (time <= Time.now))
      end
      return create_path(current) if current

      path = create_path(Time.now)
      Dir.mkdir(path)
      File.chown(uid, gid, path)
      return path
    end

    def create_path(time)
      return File.join(ROOT_DIR, 'htdocs', time.strftime('%FT%H:%M'))
    end

    def uid
      return File.stat(ROOT_DIR).uid
    end

    def gid
      return File.stat(ROOT_DIR).gid
    end
  end
end
