Gem::Specification.new do |s|
  s.name        = "gallery-gen"
  s.version     = "1.0.1"

  s.summary     = "Gallery-Generator"
  s.description = "Quickly generate a mobile-ready photo gallery from a directory of images."
  s.authors     = ["Patrick Pfeifer"]
  s.license     = "MIT"
  s.homepage    = "https://github.com/Pfiver/gallery-gen"
  s.metadata    = { "source_code_uri" => "https://github.com/Pfiver/gallery-gen" }

  s.add_runtime_dependency "rmagick", ["~> 4.2.6"]
  s.add_runtime_dependency "jekyll", ["~> 4.2.2"]

  s.executables .push "gallery-gen"
  s.files       .push *Dir.glob(%w(
    example_site/**/*
    assets/gallery.{css,js}
    PhotoSwipe/dist/*.{css,min.js}
  ))
end
