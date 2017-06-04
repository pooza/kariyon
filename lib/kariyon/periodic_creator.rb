require 'kariyon/environment'
require 'fileutils'

module Kariyon
  class PeriodicCreator
    def self.clear
      Dir.glob(File.join(dest, '/*')) do |f|
        next unless File.symlink?(f)
        if File.readlink(f).match(ROOT_DIR)
          puts "delete #{f}"
          File.unlink(f)
        end
      end
    end

    def self.create
      File.symlink(src, dest)
    end

    private
    def self.src
      return File.join(ROOT_DIR, 'bin/kariyon.rb')
    end

    def self.dest
      case Ginseng::Environment.platform.name
      when 'FreeBSD', 'Darwin'
        return File.join(self.destdir, '900.kariyon')
      when 'Debian'
        return File.join(self.destdir, 'kariyon')
      end
    end

    def self.destdir
      case Ginseng::Environment.platform.name
      when 'FreeBSD', 'Darwin'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
