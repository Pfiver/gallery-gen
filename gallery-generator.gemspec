Gem::Specification.new do |s|
  s.name        = "gallery-generator"
  s.version     = "1.1.1"

  s.summary     = "Gallery-Generator"
  s.description = "Quickly generate a mobile-ready photo gallery from a directory of images."
  s.authors     = ["Patrick Pfeifer"]
  s.email       = "patrick@patrickpfeifer.net"
  s.homepage    = "https://github.com/Pfiver/gallery-generator"

  s.license     = "MIT"

  s.add_runtime_dependency "rmagick", ["~> 4.2.6"]
  s.add_runtime_dependency "jekyll-optional-front-matter", ["~> 0.3.2"]

  s.executables .push "gallery-generator"
  s.files       .push *Dir.glob(%w(gallery.{css,js} PhotoSwipe/dist/*.{css,min.js}))
end
