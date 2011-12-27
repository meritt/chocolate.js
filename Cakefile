fs        = require 'fs'
{dirname} = require 'path'
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

  path = dirname(__filename)
  dist = path + '/dist/' + theme + '/'
  src  = path + '/themes/' + theme + '/'

  fs.stat dist, (error, stat) ->
    spawn 'rm', ['-R', dist] if stat
    spawn 'mkdir', ['-p', dist + 'js']
    spawn 'mkdir', ['-p', dist + 'css']

    spawn 'cp', ['-R', src + 'images', dist + 'images'] if fs.statSync src + 'images'

    compileJsContent dist, src, basedir
    compileCssContent dist, src, basedir

compileJsContent = (dist, src, basedir) ->
  options = JSON.parse fs.readFileSync(src + 'options.json', 'utf8')
  options.basedir = basedir

  options   = "defaultOptions = `" + JSON.stringify(options) + "`"
  templates = "templates = `" + fs.readFileSync(src + 'templates.json', 'utf8') + "`"
  chocolate = fs.readFileSync dirname(__filename) + '/src/chocolate.coffee', 'utf8'

  js = compile options + "\n\n" + templates + "\n\n" + chocolate

  fs.writeFileSync dist + 'js/chocolate.js', js
  fs.writeFileSync dist + 'js/chocolate.min.js', uglify js

compileCssContent = (dist, src, basedir) ->
  parser = new less.Parser
    paths:    [src + 'css']
    filename: 'chocolate.less'

  css = fs.readFileSync(src + 'css/chocolate.less', 'utf8')
  css = css.replace '{{basedir}}', basedir

  parser.parse css, (error, tree) ->
    css = tree.toCSS()

    fs.writeFileSync dist + 'css/chocolate.css', css
    fs.writeFileSync dist + 'css/chocolate.min.css', cssmin css