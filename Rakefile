dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'bundler/setup'
require 'kariyon'

desc 'install'
task install: [
  'kariyon:periodic:init',
  'kariyon:htdocs:init',
  'kariyon:skel:well_known_dir',
]

desc 'uninstall'
task uninstall: [
  'kariyon:periodic:clean',
  'kariyon:htdocs:clean',
]

Kariyon.load_tasks
