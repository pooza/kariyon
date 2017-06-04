ROOT_DIR = File.expand_path('..', __FILE__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))

require 'kariyon/periodic_creator'

desc 'インストール'
task :install => [
  'periodic:init',
]

desc 'アンインストール'
task :uninstall => [
  'periodic:clean',
]

namespace :periodic do
  desc 'periodicを初期化'
  task :init => [:clean, :create]

  desc 'periodicをクリア'
  task :clean do
    Kariyon::PeriodicCreator.clear
  end

  desc 'periodicにリンクを作成'
  task :create do
    Kariyon::PeriodicCreator.create
  end
end
