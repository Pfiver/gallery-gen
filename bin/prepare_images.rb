#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'digest'
require 'pathname'
require 'fileutils'

require 'rmagick'

config = YAML.load_file 'config.yml'
out_dir = "site"
out_file = out_dir + "/gallery-data.json"

data = {}
config['galleries'].each do |name, gallery|
  next unless gallery.class == Hash
  if gallery['parent']
    gallery = data[gallery['parent']].merge(gallery)
  end
  data[name] = gallery
  unless gallery[:images]
    out_path = out_dir + "/" + gallery['path']
    unless Dir.exist?(out_path)
      STDERR.puts "Creating output directory #{out_path}"
      FileUtils.mkdir_p(out_path)
    end
    images = []
    data[name].merge!({ :images => images })
    Dir.glob(File.join(gallery['path'], "**/*"))
       .select { |path| File.file? path }
       .each { |path| images.push(process(path, gallery)) }
    images.sort_by! { |it| it[:date] }
  end
  if gallery['selection']
    gallery[:images].select! { |i| gallery['selection'].include? i[:name] }
  end
end
STDERR.puts "Writing #{out_file}"
File.write out_file, JSON.pretty_generate(data)

BEGIN {
  def process(path, config)
    STDERR.puts "Processing #{path}"
    img1 = Magick::Image::read(path).first
    date1 = img1.get_exif_by_entry('DateTimeOriginal')[0][1]
    if date1
      date = DateTime.strptime(date1, '%Y:%m:%d %H:%M:%S')
      # STDERR.puts "    Date: #{date}"
    else
      date = 0
    end
    img = img1.auto_orient
    img1.destroy!
    img.strip! # strip exif data
    abs_path = File.expand_path(path)
    ext = File.extname(path).downcase
    dig = Digest::MD5.digest path
    digest = Proquint.encode(dig.unpack 'SS')
    out_dir = config['path']
    original_path = "#{out_dir}/#{digest}#{ext}"
    out = { name: digest.gsub('-', ' '), path: path, date: date,
            original: { path: original_path, width: img.columns, height: img.rows }, renditions: [] }
    Dir.chdir("site") do
      relorig = Pathname.new(abs_path).relative_path_from(File.expand_path(out_dir))
      File.symlink(relorig.to_s, original_path) unless File.exist? original_path
      config['geometries'].each do |geometry|
        img.change_geometry(geometry) do |columns, rows, i|
          rendition_path = "#{out_dir}/#{digest}-#{columns}x#{rows}#{ext}"
          render(i, rendition_path, columns, rows)
          out[:renditions].push({ path: rendition_path, width: columns, height: rows, geometry: geometry })
        end
      end
      rendition_path = "#{out_dir}/#{digest}-#{img.columns}x#{img.rows}#{ext}"
      render(img, rendition_path)
      out[:renditions].push({ path: rendition_path, width: img.columns, height: img.rows, geometry: "100%" })
    end
    img.destroy!
    out[:srcset] = out[:renditions].map { |s| s[:path] + " " + s[:width].to_s + "w" }.join(", ")
    out
  end

  def render(i, out_path, columns = nil, rows = nil)
    unless File.file? out_path
      STDERR.puts "    Generating #{out_path}"
      i = i.resize(columns, rows) if columns
      i.write(out_path) { |img| img.quality = 75; img.interlace = Magick::PlaneInterlace }
      i.destroy! if columns
    end
  end

  module Proquint
    extend self

    CONSONANTS = %w[b d f g j k l m n p r s t v x z]
    VOWELS = %w[a i o u]
    REVERSE = {}
    CONSONANTS.each_with_index { |c, i| REVERSE[c] = i }
    VOWELS.each_with_index { |c, i| REVERSE[c] = i }

    # Convert an array of uint16s to a proquint
    def encode(shorts, sep = "-")
      shorts.map do |s|
        raise ArgumentError.new("Can't encode negative numbers" ) if s < 0x0000
        raise ArgumentError.new("Can't encode numbers > 16 bits") if s > 0xffff
        CONSONANTS[(s & 0xf000) >> 12] +
            VOWELS[(s & 0x0c00) >> 10] +
        CONSONANTS[(s & 0x03c0) >>  6] +
            VOWELS[(s & 0x0030) >>  4] +
        CONSONANTS[ s & 0x000f]
      end.join sep
    end
  end
}

# vim: sw=2 ts=2 et
