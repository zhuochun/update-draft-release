#!/usr/bin/env ruby
# encoding: utf-8

require './update_draft_release'

if ARGV.empty? || ARGV[0].empty?
  puts "Missing: repository name"
  exit
end

runner = UpdateDraftRelease::Runner.new ARGV[0]
runner.update_draft_release
