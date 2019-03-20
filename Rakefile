dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'bundler/setup'
require 'kariyon'

desc 'install'
task install: [
  'kariyon:periodic:init',
  'kariyon:htdocs:init',
]

desc 'uninstall'
task uninstall: [
  'kariyon:periodic:clean',
  'kariyon:htdocs:clean',
]

Dir.glob(File.join(Kariyon::Environment.dir, 'lib/task/*.rb')).each do |f|
  require f
end
