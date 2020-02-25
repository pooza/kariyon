require 'ginseng'

module Kariyon
  def self.dir
    return File.expand_path('../..', __dir__)
  end

  def self.loader
    config = YAML.load_file(File.join(dir, 'config/autoload.yaml'))
    loader = Zeitwerk::Loader.new
    loader.inflector.inflect(config['inflections'])
    loader.push_dir(File.join(dir, 'app/lib'))
    config['dirs'].each do |d|
      loader.push_dir(File.join(dir, 'app', d))
    end
    return loader
  end
end

Kariyon.loader.setup
