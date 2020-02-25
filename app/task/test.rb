desc 'test all'
task :test do
  ENV['TEST'] = Kariyon::Package.name
  require 'test/unit'
  Dir.glob(File.join(Kariyon::Environment.dir, 'test/*.rb')).sort.each do |t|
    require t
  end
end
