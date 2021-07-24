#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'digest'
require 'pathname'
require 'fileutils'

require 'rmagick'

YAML.load_file('gallery_conf.yml').each do |gallery, config| data = []
  config['gallery'] = gallery
  out_dir = "site/" + gallery
  unless Dir.exist?(out_dir)
    STDERR.puts "Creating output directory #{out_dir}"
    FileUtils.mkdir_p(out_dir)
  end
  Dir.glob(File.join(config['path'], "**/*")).select { |path| File.file? path }.each do |path|
    data.push(process(path, config))
  end
  data.compact!.sort_by! { |it| it[:date] }
  data_file = "site/#{gallery}/gallery-data.json"
  STDERR.puts "Writing #{data_file}"
  File.write data_file, JSON.pretty_generate(data)
end

BEGIN {
  def process(path, config)
    STDERR.puts "Processing #{path}"
    img1 = Magick::Image::read(path).first
    date1 = img1.get_exif_by_entry('DateTimeOriginal')[0][1]
    return unless date1
    date = DateTime.strptime(date1, '%Y:%m:%d %H:%M:%S')
    STDERR.puts "    Date: #{date}"
    img = img1.auto_orient
    img1.destroy!
    img.strip! # strip exif data
    abs_path = File.expand_path(path)
    ext = File.extname(path).downcase
    dig = Digest::MD5.digest path
    digest = Proquint.encode(dig.unpack 'SS')
    out_dir = config['gallery']
    original_path = "#{out_dir}/#{digest}#{ext}"
    out = { name: digest.gsub('-', ' '), path: path, date: date,
            original: { path: original_path, width: img.columns, height: img.rows }, renditions: [] }
    Dir.chdir("site") do
      File.symlink(abs_path, original_path) unless File.exist? original_path
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
      i.write(out_path) { self.quality = 75; self.interlace = Magick::PlaneInterlace }
      i.destroy! if columns
    end
  end

  module Proquint
    extend self

    CONSONANTS = %w[b d f g h j k l m n p r s t v z]
    VOWELS = %w[a i o u]
    REVERSE = {}
    CONSONANTS.each_with_index { |c, i| REVERSE[c] = i }
    VOWELS.each_with_index { |c, i| REVERSE[c] = i }

    # Convert an array of uint16s to a proquint
    def encode(shorts, sep = "-")
      shorts.map do |s|
        raise ArgumentError.new("Can't encode negative numbers") if s < 0
        raise ArgumentError.new("Can't encode numbers > 16 bits") if s > 0xffff
        CONSONANTS[(s & 0xf000) >> 12] +
            VOWELS[(s & 0x0c00) >> 10] +
        CONSONANTS[(s & 0x03c0) >>  6] +
            VOWELS[(s & 0x0030) >>  4] +
        CONSONANTS[ s & 0x000f]
      end
      .join(sep)
    end
  end
}

# vim: sw=2 ts=2 et
