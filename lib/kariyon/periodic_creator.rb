require 'kariyon/environment'
require 'kariyon/deployer'
require 'fileutils'

module Kariyon
  class PeriodicCreator
    def self.clean
      Dir.glob(File.join(destroot, '/*')) do |f|
        next unless File.symlink?(f)
        if File.readlink(f).match(ROOT_DIR)
          puts "delete #{f}"
          File.unlink(f)
        end
      end
    end

    def self.create
      if minc?
        raise 'MINCをアンインストールしてください。'
        exit 1
      end
      puts "link #{src} -> #{dest}"
      File.symlink(src, dest)
    end

    private
    def self.minc?
      return Kariyon::Deployer.minc?(Kariyon::Deployer.dest)
    end

    def self.src
      return File.join(ROOT_DIR, 'bin/kariyon.rb')
    end

    def self.dest
      case Kariyon::Environment.platform
      when 'FreeBSD', 'Darwin'
        return File.join(destroot, "900.kariyon-#{Kariyon::Environment.name}")
      when 'Debian'
        return File.join(destroot, "kariyon-#{Kariyon::Environment.name.gsub('.', '-')}")
      end
    end

    def self.destroot
      case Kariyon::Environment.platform
      when 'FreeBSD', 'Darwin'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
