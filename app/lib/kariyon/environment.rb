module Kariyon
  class Environment < Ginseng::Environment
    def self.name
      return File.basename(dir)
    end

    def self.dir
      return Kariyon.dir
    end
  end
end
