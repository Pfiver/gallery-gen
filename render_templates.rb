#!/usr/bin/env ruby

require 'json'
require 'liquid'

config_file = ARGV[0] || "config.yml"
STDERR.puts "Reading config from " + config_file
config = YAML.load_file(config_file)
$gallery = config['gallery']
$data = JSON.parse File.read "site/#{$gallery['path']}/gallery-data.json"
if $gallery['selection']
  $data.select! { |i| $gallery['selection'].include? i['name'] }
end

module GalleryTag
  class Block < Liquid::Block
    def initialize(tag_name, markup, tokens)
      super
    end
    def render(context)
      result = []
      context.stack do
        $data.each do |i|
          context['image'] = i
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
out_basename = config_file.gsub(/\..*/, "")
out_basename = "index" if out_basename == "config"
out_name = "site/" + out_basename + ".html"
STDERR.puts "Writing " + out_name
File.write out_name, template.render!({'title' => config['title']})

# vim: sw=2 ts=2 et
