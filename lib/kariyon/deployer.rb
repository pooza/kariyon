require 'kariyon/environment'
require 'kariyon/mail_deliverer'
require 'fileutils'
require 'time'
require 'etc'

module Kariyon
  class Deployer
    def self.clean
      Dir.glob(File.join(destroot, '*')) do |f|
        next unless kariyon?(f)
        puts "delete #{f}"
        FileUtils.rm_rf(f)
      end
    end

    def self.create
      raise 'MINCをアンインストールしてください。' if minc?(dest)
      puts "create #{dest}"
      Dir.mkdir(dest, 0755)
      FileUtils.touch(File.join(dest, '.kariyon'))
      update
    end

    def self.update
      link = File.join(dest, 'www')
      if File.exist?(link)
        puts "delete #{link}" unless Kariyon::Environment.cron?
        File.unlink(link)
      end
      puts "link #{current_doc} -> #{link}" unless Kariyon::Environment.cron?
      File.symlink(current_doc, link)
    end

    def self.minc? (f)
      return File.exist?(File.join(f, 'webapp/lib/MincSite.class.php'))
    end

    def self.kariyon? (f)
      return File.exist?(File.join(f, '.kariyon'))
    end

    private
    def self.destroot
      case Kariyon::Environment.platform
      when 'FreeBSD'
        return '/usr/local/www/apache24/data'
      else
        puts "#{Kariyon::Environment.platform}は未対応です。"
        exit 1
      end
    end

    def self.dest
      return File.join(destroot, Kariyon::Environment.name)
    end

    def self.current_doc
      format = '%FT%H:%M'
      if Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).empty?
        path = File.join(ROOT_DIR, 'htdocs', Time.now.strftime(format))
        puts "create #{path}"
        Dir.mkdir(path)
        File.chown(uid, gid, path)
        return path
      end

      current = nil
      errors = []
      Dir.glob(File.join(ROOT_DIR, 'htdocs/*')).sort.each do |f|
        next unless File.directory?(f)
        begin
          time = Time.parse(File.basename(f))
        rescue ArgumentError
          errors.push("フォルダ名 '#{File.basename(f)}' が正しくありません。")
          next
        end
        if current.nil? || ((current < time) && (time <= Time.now))
          current = time
        end
      end
      send_errors(errors) unless errors.empty?
      return File.join(ROOT_DIR, 'htdocs', current.strftime(format))
    end

    def self.send_errors (errors)
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
