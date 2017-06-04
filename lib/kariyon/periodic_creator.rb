require 'kariyon/environment'
require 'kariyon/deployer'
require 'fileutils'

module Kariyon
  class PeriodicCreator
    def self.clear
      Dir.glob(File.join(destdir, '/*')) do |f|
        next unless File.symlink?(f)
        if File.readlink(f).match(ROOT_DIR)
          puts "delete #{f}"
          File.unlink(f)
        end
      end
    end

    def self.create
      raise 'MINCをアンインストールしてください。' if minc?
      puts "link #{src} -> #{dest}"
      File.symlink(src, dest)
    end

    private
    def self.minc?
      return Kariyon::Deployer.minc?(
        File.join(Kariyon::Deployer.destdir, Kariyon::Environment.name)
      )
    end

    def self.src
      return File.join(ROOT_DIR, 'bin/kariyon.rb')
    end

    def self.dest
      case Kariyon::Environment.platform
      when 'FreeBSD', 'Darwin'
        return File.join(self.destdir, "900.kariyon-#{Kariyon::Environment.name}")
      when 'Debian'
        return File.join(self.destdir, "kariyon-#{Kariyon::Environment.name.gsub('.', '-')}")
      end
    end

    def self.destdir
      case Kariyon::Environment.platform
      when 'FreeBSD', 'Darwin'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
