dir = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

require 'kariyon'
module Kariyon
  ENV['RAKE'] = Package.full_name
  load_tasks
end
