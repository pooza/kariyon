dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'kariyon'
ENV['RAKE'] = Kariyon::Package.full_name
Kariyon.load_tasks
