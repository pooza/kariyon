#!/usr/bin/env ruby

ROOT_DIR = File.expand_path('../..', __FILE__)
$LOAD_PATH.push(File.join(ROOT_DIR, 'lib'))

require 'kariyon/deployer'

Kariyon::Deployer.update