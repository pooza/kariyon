ROOT_DIR = File.expand_path(__dir__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(ROOT_DIR, 'Gemfile')
ENV['SSL_CERT_FILE'] ||= File.join(ROOT_DIR, 'cert/cacert.pem')

require 'bundler/setup'
require 'kariyon'

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

namespace :cert do
  desc 'update cert'
  task :update do
    require 'httparty'
    File.write(
      File.join(ROOT_DIR, 'cert/cacert.pem'),
      HTTParty.get('https://curl.haxx.se/ca/cacert.pem'),
    )
  end
end

namespace :periodic do
  task init: [:clean, :create]

  desc 'periodicをクリア'
  task :clean do
    Kariyon::PeriodicCreator.instance.clean
  end

  desc 'periodicにリンクを作成'
  task :create do
    Kariyon::PeriodicCreator.instance.create
  end
end

namespace :htdocs do
  task init: [:clean, :create]

  desc 'htdocsをクリア'
  task :clean do
    Kariyon::Deployer.instance.clean
  end

  desc 'htdocsにリンクを作成'
  task :create do
    Kariyon::Deployer.instance.create
  end

  desc 'htdocsのリンクを更新'
  task :update do
    Kariyon::Deployer.instance.update
  end
end
