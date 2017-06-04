require 'kariyon/environment'
require 'fileutils'

module Kariyon
  class Deployer
    def self.clear
      Dir.glob(File.join(destdir, '/*')) do |f|
        next unless kariyon?(f)
        puts "delete #{f}"
        FileUtils.rm_rf(f)
      end
    end

    def self.create
      dir = File.join(destdir, Kariyon::Environment.name)
      raise 'MINCをアンインストールしてください。' if minc?(dir)
      puts "create #{dir}"
      Dir.mkdir(dir, 0755)
      FileUtils.touch(File.join(dir, '.kariyon'))
    end

    def self.minc? (f)
      return File.symlink?(f) && File.exist?(File.join(f, 'webapp/lib/MincSite.class.php'))
    end

    def self.destdir
      return '/usr/local/www/apache24/data'
    end

    private
    def self.kariyon? (f)
      return File.directory?(f) && File.exist?(File.join(f, '.kariyon'))
    end
  end
end
