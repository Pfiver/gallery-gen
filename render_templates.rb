#!/usr/bin/env ruby

require 'json'
require 'liquid'

module GalleryTag
  class Block < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
      attrs = Hash[markup.scan(Liquid::TagAttributes)]
      @data_path = "site/#{attrs['config']}/gallery-data.json"
    end
    def render(context)
      result = []
      context.stack do
        (JSON.parse File.read @data_path).each do |data|
          context['image'] = data
          result.push super(context)
        end
      end
      result
    end
  end
end

Liquid::Template.register_tag 'gallery', GalleryTag::Block

input = File.read "index.html"
template = Liquid::Template.parse input
File.write "site/index.html", template.render!(nil,
  registers: { file_system: Liquid::LocalFileSystem.new(".", "%s.html") })

# vim: sw=2 ts=2 et
