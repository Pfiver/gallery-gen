all:
	gem install --user-install gallery_generator
	rm -rf site
	prepare_images.rb
	render_templates.rb

all_dev:
	rm -rf site
	../bin/prepare_images.rb
	../bin/render_templates.rb
