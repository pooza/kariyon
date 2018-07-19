require 'kariyon/environment'
require 'kariyon/alerter'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    def self.clean
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.glob(File.join(destroot, '*')) do |f|
        begin
          if kariyon?(f) && File.readlink(File.join(f, 'www')).match(ROOT_DIR)
            FileUtils.rm_rf(f)
            Alerter.log({message: "削除 #{f}"})
          end
        rescue => e
          Alerter.alert({error: "#{e.class}: #{e.message}"})
        end
      end
    rescue => e
      Alerter.alert({error: "#{e.class}: #{e.message}"})
      exit 1
    end

    def self.create
      raise 'MINCをアンインストールしてください。' if minc?
      Dir.mkdir(dest, 0o775)
      FileUtils.touch(File.join(dest, '.kariyon'))
      update
      Alerter.log({message: "作成 #{dest}"})
    rescue => e
      Alerter.alert({error: "#{e.class}: #{e.message}"})
      exit 1
    end

    def self.update
      link = File.join(dest, 'www')
      root = read_root_path
      return if File.exist?(link) && (File.readlink(link) == root)
      File.unlink(link) if File.exist?(link)
      File.symlink(root, link)
      Alerter.alert({message: "リンク #{root} -> #{link}"})
    rescue => e
      Alerter.alert({error: "#{e.class}: #{e.message}"})
      exit 1
    end

    def self.minc?(path = nil)
      path ||= dest
      return minc3?(path) || minc2?(path)
    end

    def self.minc3?(path = nil)
      path ||= dest
      return File.exist?(File.join(path, 'webapp/lib/Minc3/Site.class.php'))
    end

    def self.minc2?(path = nil)
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
          Alerter.alert({message: "フォルダ名不正 '#{File.basename(f)}'"})
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
