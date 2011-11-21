fs        = require 'fs'
uglify    = require 'uglify-js'
{compile} = require 'coffee-script'

task 'build', 'Build lib/ from src/', ->
  content = compile fs.readFileSync 'src/gallery.coffee', 'utf8'
  fs.writeFileSync 'lib/gallery.js', content
  fs.writeFileSync 'lib/gallery.min.js', uglify content