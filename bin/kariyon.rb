#!/usr/bin/env ruby

path = File.expand_path(__FILE__)
path = File.expand_path(File.readlink(path)) while File.symlink?(path)
dir = File.expand_path('../..', path)
$LOAD_PATH.unshift(File.join(dir, 'app/lib'))
ENV['BUNDLE_GEMFILE'] ||= File.join(dir, 'Gemfile')

Dir.chdir(dir)
require 'kariyon'
module Kariyon
  sleep 3
  Deployer.instance.update
end
