fs        = require 'fs'
{dirname} = require 'path'
{spawn}   = require 'child_process'
{compile} = require 'coffee-script'
less      = require 'less'
uglify    = require 'uglify-js'
{cssmin}  = require 'cssmin'

option '-t', '--themes [NAME]', 'theme for compiled gallery code'

task 'build', 'Build gallery', (options) ->
  theme = options.themes or 'default'

  path = dirname(__filename)
  dist = path + '/lib/' + theme + '/'
  src  = path + '/themes/' + theme + '/'

  fs.stat dist, (error, stat) ->
    spawn 'rm', ['-R', dist] if stat
    spawn 'mkdir', ['-p', dist + 'js']
    spawn 'mkdir', ['-p', dist + 'css']

    spawn 'cp', ['-R', src + 'images', dist] if fs.statSync src + 'images'

    compileJsContent dist, src
    compileCssContent dist, src

compileJsContent = (dist, src) ->
  options   = "defaultOptions = `" + fs.readFileSync(src + 'options.json', 'utf8') + "`"
  templates = "templates = `" + fs.readFileSync(src + 'templates.json', 'utf8') + "`"
  gallery   = fs.readFileSync dirname(__filename) + '/src/gallery.coffee', 'utf8'

  js = compile options + "\n\n" + templates + "\n\n" + gallery

  fs.writeFileSync dist + 'js/gallery.js', js
  fs.writeFileSync dist + 'js/gallery.min.js', uglify js

compileCssContent = (dist, src) ->
  parser = new less.Parser
    paths:    [src + 'css']
    filename: 'gallery.less'

  parser.parse fs.readFileSync(src + 'css/gallery.less', 'utf8'), (error, tree) ->
    css = tree.toCSS()

    fs.writeFileSync dist + 'css/gallery.css', css
    fs.writeFileSync dist + 'css/gallery.min.css', cssmin css