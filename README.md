# gallery-gen

Usage:

    $ gem install gallery-gen
    $ rm -rf _site _data
    $ mkdir galleries
    $ cp -va <pics> galleries
    $ vi _config.yml

    $ gallery-gen

    $ jekyll build
    $ jekyll serve


Release process:

1. get a rubygems.org api token:
 
       ➜  ~ cat .gem/credentials
       ---
       :rubygems_api_key: rubygems_...

2. update `gallery-gen.gemspec`
3. `$ gem build gallery-gen.gemspec`
4. `$ gem push gallery-gen-*.gem`
5. `$ gem install --user gallery-gen-*.gem`
