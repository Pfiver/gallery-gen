#!/usr/bin/env ruby

config = YAML.load_file "config.yml"
$data = JSON.parse File.read "site/gallery-data.json"

Dir.glob(File.join('.', "*.html"))
   .select { |path| File.file? path }
   .each do |file|
  out = "site/" + file
  File.write out, Liquid::Template
    .parse(File.read(file))
    .render!(config)
  STDERR.puts "Wrote " + out
end

base = Pathname.new(__dir__ + "/..").realpath.to_s
Dir.glob(%w(gallery.{css,js} PhotoSwipe/dist/*.{css,min.js}), base: base)
   .each { |path| FileUtils.cp File.join(base, path), 'site', verbose: true }

BEGIN {

  require 'yaml'
  require 'json'
  require 'pathname'
  require 'fileutils'

  require 'liquid'

  def get_gallery(name)
    gallery = $data[name]
    gallery['name'] = name
    gallery
  end

  class Gallery < Liquid::Block
    def initialize(tag_name, markup, context)
      super
      @name = markup.strip
      @gallery = get_gallery @name
      $gallery = @gallery unless $gallery
    end
    def render(context)
      context['gallery'] = @gallery
      super
    end
  end

  class Galleries < Liquid::Block
    def render(context)
      result = []
      $data.keys.each do |name|
        context.stack do
          gallery = get_gallery name
          context['gallery'] = gallery
          $gallery = gallery unless $gallery
          result.push super
        end
      end
      result.join
    end
  end

  class Images < Liquid::Block
    def render(context)
      result = ["<!-- start '#{context['gallery']['name']}' gallery -->\n"]
      context['gallery']['images'].each do |i|
        context.stack do
          context['image'] = i
          result.push super(context)
        end
      end
      final_indent = super(context)
                       .match(/\n\s*$/)&.values_at(0)
      result += [final_indent, "<!-- end '#{context['gallery']['name']}' gallery -->"]
      result.join
    end
  end

  Liquid::Template.register_tag 'galleries', Galleries
  Liquid::Template.register_tag 'gallery', Gallery
  Liquid::Template.register_tag 'images', Images
}

# vim: sw=2 ts=2 et
