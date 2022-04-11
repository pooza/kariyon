module Kariyon
  class Skeleton
    def initialize
      @logger = Logger.new
    end

    def copy_to(dir)
      files.each do |src|
        dest = File.join(dir, File.basename(src))
        next if File.exist?(dest)
        if File.symlink?(src)
          src = File.readlink(src)
          File.symlink(src, dest)
          File.lchown(Environment.uid, Environment.gid, dest)
          @logger.info(action: 'link', source: src, dest: dest)
        else
          FileUtils.cp(src, dir)
          @logger.info(action: 'copy', source: src, dest: dir)
        end
        File.chown(Environment.uid, Environment.gid, dest)
      end
    end

    def dir
      return File.join(Environment.dir, 'skel')
    end

    def files
      return enum_for(__method__) unless block_given?
      ['/*', '/.*'].each do |pattern|
        Dir.glob(File.join(dir, pattern)).each do |f|
          next if ignore_names.member?(File.basename(f))
          yield f
        end
      end
    end

    def link_well_known_dir
      dest = File.join(dir, '.well-known')
      return if File.exist?(dest)
      File.symlink(Deployer.instance.well_known_dir, dest)
      File.lchown(Environment.uid, Environment.gid, dest)
      @logger.info(action: 'link', source: src, dest: dest)
    end

    private

    def ignore_names
      return [
        '.',
        '..',
        '.gitignore',
      ]
    end
  end
end
