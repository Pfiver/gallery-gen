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
  data.sort_by! { |it| it[:date] }
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
    ext = File.extname(path)
    digest = (Digest::MD5.hexdigest path)[0..10]
    out_dir = config['gallery']
    out_path = "#{out_dir}/#{digest}-#{img.columns}x#{img.rows}#{ext}"
    out = { name: File.basename(path, ext), path: path, date: date,
            original: { path: out_path, width: img.columns, height: img.rows }, resized: [] }
    Dir.chdir("site") do
      unless File.file? out_path
        STDERR.puts "    Generating #{out_path}"
        img.write (out_path) { self.quality = 75; self.interlace = Magick::PlaneInterlace }
      end
      config['geometries'].each do |geometry|
        img.change_geometry(geometry) {|columns, rows, i|
          rendition_path = "#{out_dir}/#{digest}-#{columns}x#{rows}#{ext}"
          out[:resized].push({ path: rendition_path, width: columns, height: rows, geometry: geometry })
          unless File.file? rendition_path
            STDERR.puts "    Generating #{rendition_path}"
            r = i.resize(columns, rows)
            r.write(rendition_path) { self.quality = 75; self.interlace = Magick::PlaneInterlace }
            r.destroy!
          end
        }
      end
    end
    img.destroy!
    out[:srcset] = out[:resized].map { |s| s[:path] + " " + s[:width].to_s + "w, " }.join("") + out[:original][:path] + " " + out[:original][:width].to_s + "w"
    out
  end
}

# vim: sw=2 ts=2 et
