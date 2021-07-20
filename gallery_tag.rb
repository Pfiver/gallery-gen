require 'json'
require 'liquid'
require_relative 'image_processor'

configs = { gallery: {} }

module LiquidGallery
  class Block < Liquid::Block
    include ImageProcessor, LiquidGallery
    def initialize(tag_name, markup, tokens)
      super
      @attributes = symbolize_keys(Hash[markup.scan(Liquid::TagAttributes)])
      @config = symbolize_keys(YAML.load_file('gallery_configs.yml')[@attributes[:config]])
    end
    def render(context)
      result = []
      data_path = "site/#{@attributes[:config]}.json"
      if File.file? data_path
        context.stack do
          (JSON.parse File.read data_path).sort_by {|data| data["original"]["path"] }.each do |data|
            context['image'] = data
            result.push super(context)
          end
        end
      else
        data = []
        context.stack do
          Dir.glob(File.join(@config[:path], "**/*")).select { |path| File.file? path }.sort.each do |path|
            data.push(context['image'] = stringify_keys(process(path, @config)))
            result.push super(context)
          end
        end
        File.write data_path, JSON.pretty_generate(data)
      end
      result
    end
  end
  def symbolize_keys(hash) JSON.parse JSON.dump(hash), symbolize_names: true end
  def stringify_keys(hash) JSON.parse JSON.dump(hash), symbolize_names: false end
end

Liquid::Template.register_tag 'gallery', LiquidGallery::Block
