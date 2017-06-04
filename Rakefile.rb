ROOT_DIR = File.expand_path('..', __FILE__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))

require 'kariyon/periodic_creator'
require 'kariyon/deployer'

desc 'インストール'
task :install => [
  'periodic:init',
  'htdocs:init',
]

desc 'アンインストール'
task :uninstall => [
  'periodic:clean',
  'htdocs:clean',
]

namespace :periodic do
  task :init => [:clean, :create]

  desc 'periodicをクリア'
  task :clean do
    Kariyon::PeriodicCreator.clean
  end

  desc 'periodicにリンクを作成'
  task :create do
    Kariyon::PeriodicCreator.create
  end
end

namespace :htdocs do
  task :init => [:clean, :create]

  desc 'htdocsをクリア'
  task :clean do
    Kariyon::Deployer.clean
  end

  desc 'htdocsにリンクを作成'
  task :create do
    Kariyon::Deployer.create
  end
end
