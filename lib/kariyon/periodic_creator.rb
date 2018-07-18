require 'kariyon/environment'
require 'kariyon/deployer'
require 'kariyon/alerter'
require 'fileutils'

module Kariyon
  class PeriodicCreator
    def self.clean
      begin
        raise 'MINCをアンインストールしてください。' if Deployer.minc?
      rescue => e
        Alerter.alert({error: "#{e.class}: #{e.message}"})
        exit 1
      end

      Dir.glob(File.join(destroot, '*')) do |f|
        begin
          if File.symlink?(f) && File.readlink(f).match(ROOT_DIR)
            File.unlink(f)
            Alerter.log({message: "削除 #{f}"})
          end
        rescue => e
          Alerter.alert({error: "#{e.class}: #{e.message}"})
        end
      end
    end

    def self.create
      raise 'MINCをアンインストールしてください。' if Deployer.minc?
      File.symlink(src, dest)
      Alerter.log({message: "リンク #{src} -> #{dest}"})
    rescue => e
      Alerter.alert({error: "#{e.class}: #{e.message}"})
      exit 1
    end

    def self.src
      return File.join(ROOT_DIR, 'bin/kariyon.rb')
    end

    def self.dest
      case Environment.platform
      when 'FreeBSD', 'Darwin'
        return File.join(destroot, "900.kariyon-#{Environment.name}")
      when 'Debian'
        return File.join(destroot, "kariyon-#{Environment.name.tr('.', '-')}")
      end
    end

    def self.destroot
      case Environment.platform
      when 'FreeBSD', 'Darwin'
        return '/usr/local/etc/periodic/frequently'
      when 'Debian'
        return '/etc/cron.frequently'
      end
    end
  end
end
