fs        = require 'fs'
path      = require 'path'
{spawn}   = require 'child_process'
{compile} = require 'coffee-script'
less      = require 'less'
uglify    = require 'uglify-js'
{cssmin}  = require 'cssmin'

option '-t', '--themes [NAME]', 'theme for compiled chocolate code'
option '-b', '--basedir [DIR]', 'directory with css, js, image folders'

task 'build', 'Build chocolate.js', (options) ->
  theme   = options.themes  or 'default'
  basedir = options.basedir or '/chocolate'
  current = path.dirname __filename

  dist = path.normalize current + '/dist/' + theme + '/'
  src  = path.normalize current + '/themes/' + theme + '/'

  fs.stat dist, (error, stat) ->
    spawn 'rm', ['-R', dist] if stat
    spawn 'mkdir', ['-p', dist + 'js']
    spawn 'mkdir', ['-p', dist + 'css']

    spawn 'cp', ['-R', src + 'images', dist + 'images'] if fs.statSync src + 'images'

    compileJsContent dist, src, basedir
    compileCssContent dist, src, basedir

compileJsContent = (dist, src, basedir) ->
  current = path.dirname __filename
  source  = path.normalize current + '/src/chocolate.coffee'

  options = "defaultOptions = `" + fs.readFileSync(src + 'options.json', 'utf8') + "`"

  templates = fs.readFileSync src + 'templates.json', 'utf8'
  templates = templates.replace /\{\{basedir\}\}/gi, basedir
  templates = "templates = `" + templates + "`"

  chocolate = fs.readFileSync source, 'utf8'

  js = compile options + "\n\n" + templates + "\n\n" + chocolate

  fs.writeFileSync path.normalize(dist + 'js/chocolate.js'), js
  fs.writeFileSync path.normalize(dist + 'js/chocolate.min.js'), uglify js

compileCssContent = (dist, src, basedir) ->
  parser = new less.Parser
    paths:    [src + 'css']
    filename: 'chocolate.less'

  source = path.normalize src + 'css/chocolate.less'

  css = fs.readFileSync source, 'utf8'
  css = css.replace '{{basedir}}', basedir

  parser.parse css, (error, tree) ->
    css = tree.toCSS()

    fs.writeFileSync path.normalize(dist + 'css/chocolate.css'), css
    fs.writeFileSync path.normalize(dist + 'css/chocolate.min.css'), cssmin css