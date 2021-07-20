#!/usr/bin/env ruby

require 'liquid'

require_relative 'gallery_tag'

input = File.read "index.html"
template = Liquid::Template.parse input
File.write "site/index.html", template.render!(nil,
  registers: { file_system: Liquid::LocalFileSystem.new(".", "%s.html") })
