require 'kariyon/environment'
require 'kariyon/mail_deliverer'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    def self.clean
      begin
        raise 'MINCをアンインストールしてください。' if minc?
      rescue => e
        puts "#{e.class}: #{e.message}"
        exit 1
      end

      Dir.glob(File.join(destroot, '*')) do |f|
        begin
          if kariyon?(f) && File.readlink(File.join(f, 'www')).match(ROOT_DIR)
            puts "delete #{f}"
            FileUtils.rm_rf(f)
          end
        rescue => e
          puts "#{e.class}: #{e.message}"
        end
      end
    end

    def self.create
      begin
        raise 'MINCをアンインストールしてください。' if minc?
        puts "create #{dest}"
        Dir.mkdir(dest, 0755)
        FileUtils.touch(File.join(dest, '.kariyon'))
        update
      rescue => e
        puts "#{e.class}: #{e.message}"
        exit 1
      end
    end

    def self.update
      begin
        link = File.join(dest, 'www')
        if File.exist?(link)
          puts "delete #{link}" unless Kariyon::Environment.cron?
          File.unlink(link)
        end
        puts "link #{current_doc} -> #{link}" unless Kariyon::Environment.cron?
        File.symlink(current_doc, link)
      rescue => e
        puts "#{e.class}: #{e.message}"
        exit 1
      end
    end

    def self.minc? (f = nil)
      f ||= dest
      return File.exist?(File.join(f, 'webapp/lib/MincSite.class.php'))
    end

    def self.kariyon? (f = nil)
      f ||= dest
      return File.exist?(File.join(f, '.kariyon'))
    end

    private
    def self.destroot
      case Kariyon::Environment.platform
      when 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        raise "#{Kariyon::Environment.platform}は未対応です。"
      end
    end

    def self.dest
      return File.join(destroot, Kariyon::Environment.name)
    end

    def self.current_doc
      current = nil
      errors = []
      Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          puts "invalid folder name: #{File.basename(f)}"
          errors.push("フォルダ名 '#{File.basename(f)}' が正しくありません。")
          next
        end
        if current.nil? || ((current < time) && (time <= Time.now))
          current = time
        end
      end
      alert(errors) unless errors.empty?

      if current.nil?
        path = doc_path(Time.now)
        puts "create #{path}"
        Dir.mkdir(path)
        File.chown(uid, gid, path)
        return path
      else
        return doc_path(current)
      end
    end

    def self.doc_path (time)
      return File.join(ROOT_DIR, 'htdocs', time.strftime('%FT%H:%M'))
    end

    def self.alert (errors)
      mail = Kariyon::MailDeliverer.new
      mail.subject = 'kariyon日付設定エラー'
      mail.priority = 2
      mail.body = errors.join("\n")
      mail.deliver!
    end

    def self.uid
      return File.stat(ROOT_DIR).uid
    end

    def self.gid
      return File.stat(ROOT_DIR).gid
    end
  end
end
