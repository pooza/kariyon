ROOT_DIR = File.expand_path(__dir__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))

ENV['BUNDLE_GEMFILE'] ||= File.join(ROOT_DIR, 'Gemfile')
require 'bundler/setup'
require 'kariyon/periodic_creator'
require 'kariyon/deployer'

desc 'インストール'
task install: [
  'periodic:init',
  'htdocs:init',
]

desc 'アンインストール'
task uninstall: [
  'periodic:clean',
  'htdocs:clean',
]

namespace :periodic do
  task init: [:clean, :create]

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
  task init: [:clean, :create]

  desc 'htdocsをクリア'
  task :clean do
    Kariyon::Deployer.clean
  end

  desc 'htdocsにリンクを作成'
  task :create do
    Kariyon::Deployer.create
  end

  desc 'htdocsのリンクを更新'
  task :update do
    Kariyon::Deployer.update
  end
end
