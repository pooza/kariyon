require 'kariyon/environment'
require 'kariyon/slack'
require 'kariyon/logger'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    def self.clean
      begin
        raise 'MINCをアンインストールしてください。' if minc?
      rescue => e
        message = {message: "#{e.class}: #{e.message}"}
        Slack.broadcast(message)
        Logger.new.error(message)
        exit 1
      end

      Dir.glob(File.join(destroot, '*')) do |f|
        begin
          if kariyon?(f) && File.readlink(File.join(f, 'www')).match(ROOT_DIR)
            message = {message: "削除 #{f}"}
            Slack.broadcast(message)
            Logger.new.info(message)
            FileUtils.rm_rf(f)
          end
        rescue => e
          message = {message: "#{e.class}: #{e.message}"}
          Slack.broadcast(message)
          Logger.new.error(message)
        end
      end
    end

    def self.create
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.mkdir(dest, 0o775)
      FileUtils.touch(File.join(dest, '.kariyon'))
      update
      message = {message: "作成 #{dest}"}
      Slack.broadcast(message)
      Logger.new.info(message)
    rescue => e
      message = {message: "#{e.class}: #{e.message}"}
      Slack.broadcast(message)
      Logger.new.error(message)
      exit 1
    end

    def self.update
      link = File.join(dest, 'www')
      root = read_root_path
      return if File.exist?(link) && (File.readlink(link) == root)
      File.unlink(link) if File.exist?(link)
      File.symlink(root, link)
      message = {message: "リンク #{root} -> #{link}"}
      Slack.broadcast(message)
      Logger.new.info(message)
    rescue => e
      message = {message: "#{e.class}: #{e.message}"}
      Slack.broadcast(message)
      Logger.new.error(message)
      exit 1
    end

    def self.minc?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, 'webapp/lib/MincSite.class.php'))
    end

    def self.kariyon?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, '.kariyon'))
    end

    def self.destroot
      case Environment.platform
      when 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        raise "#{Environment.platform}は未対応です。"
      end
    end

    def self.dest
      return File.join(destroot, Environment.name)
    end

    def self.read_root_path
      current = nil
      Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          message = {message: "フォルダ名不正 '#{File.basename(f)}'"}
          Slack.broadcast(message)
          Logger.new.error(message)
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

    def self.create_path(time)
      return File.join(ROOT_DIR, 'htdocs', time.strftime('%FT%H:%M'))
    end

    def self.uid
      return File.stat(ROOT_DIR).uid
    end

    def self.gid
      return File.stat(ROOT_DIR).gid
    end
  end
end
