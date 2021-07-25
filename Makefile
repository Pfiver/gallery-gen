all:
	#mkdir -p site
	#rm -rf site/*
	ruby prepare_images.rb
	ruby render_templates.rb config.yml
	ruby render_templates.rb selection.config.yml
	bash -c "cp dot.htaccess site/.htaccess"
	bash -c "cp gallery.{css,js} PhotoSwipe/dist/*.{css,min.js} site"
