fs        = require 'fs'
{dirname} = require 'path'
{spawn}   = require 'child_process'
{compile} = require 'coffee-script'
less      = require 'less'
uglify    = require 'uglify-js'
{cssmin}  = require 'cssmin'

option '-t', '--themes [NAME]', 'theme for compiled gallery code'
option '-b', '--basedir [DIR]', 'directory with css, js, image folders'

task 'build', 'Build gallery', (options) ->
  theme   = options.themes  or 'default'
  basedir = options.basedir or '/gallery'

  path = dirname(__filename)
  dist = path + '/lib/' + theme + '/'
  src  = path + '/themes/' + theme + '/'

  fs.stat dist, (error, stat) ->
    spawn 'rm', ['-R', dist] if stat
    spawn 'mkdir', ['-p', dist + 'js']
    spawn 'mkdir', ['-p', dist + 'css']

    spawn 'cp', ['-R', src + 'images', dist] if fs.statSync src + 'images'

    compileJsContent dist, src, basedir
    compileCssContent dist, src, basedir

compileJsContent = (dist, src, basedir) ->
  options = JSON.parse fs.readFileSync(src + 'options.json', 'utf8')
  options.basedir = basedir

  options   = "defaultOptions = `" + JSON.stringify(options) + "`"
  templates = "templates = `" + fs.readFileSync(src + 'templates.json', 'utf8') + "`"
  gallery   = fs.readFileSync dirname(__filename) + '/src/gallery.coffee', 'utf8'

  js = compile options + "\n\n" + templates + "\n\n" + gallery

  fs.writeFileSync dist + 'js/gallery.js', js
  fs.writeFileSync dist + 'js/gallery.min.js', uglify js

compileCssContent = (dist, src, basedir) ->
  parser = new less.Parser
    paths:    [src + 'css']
    filename: 'gallery.less'

  css = fs.readFileSync(src + 'css/gallery.less', 'utf8')
  css = css.replace '{{basedir}}', basedir

  parser.parse css, (error, tree) ->
    css = tree.toCSS()

    fs.writeFileSync dist + 'css/gallery.css', css
    fs.writeFileSync dist + 'css/gallery.min.css', cssmin css