module Kariyon
  class Skeleton
    def copy_to(dest)
      files.each do |f|
        p f
      end
    end

    def dir
      return File.join(ROOT_DIR, 'skel')
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
