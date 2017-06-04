require 'kariyon/environment'
require 'fileutils'

module Kariyon
  class Deployer
    def self.clean
      Dir.glob(File.join(destroot, '/*')) do |f|
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
    end

    def self.minc? (f)
      return File.symlink?(f) && File.exist?(File.join(f, 'webapp/lib/MincSite.class.php'))
    end

    def self.kariyon? (f)
      return File.directory?(f) && File.exist?(File.join(f, '.kariyon'))
    end

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
  end
end
