#!/usr/bin/env ruby

path = File.expand_path(__FILE__)
path = File.expand_path(File.readlink(path)) while File.symlink?(path)
dir = File.expand_path('../..', path)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

Dir.chdir(dir)
require 'kariyon'
module Kariyon
  # 毎分の cron から呼ばれる（#306）。前の回が終わっていなければ、この回は何もしない。
  lock_path = File.join('/tmp', "#{Package.name}-#{Environment.name}.lock")
  File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lock|
    exit unless lock.flock(File::LOCK_EX | File::LOCK_NB)
    Deployer.instance.update
  end
end
