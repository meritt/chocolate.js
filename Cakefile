fs        = require 'fs'
path      = require 'path'
util      = require 'util'
{compile} = require 'coffee-script'
less      = require 'less'
uglify    = require 'uglify-js'
{cssmin}  = require 'cssmin'

option '-t', '--themes [NAME]', 'theme for compiled chocolate code'
option '-b', '--basedir [DIR]', 'directory with css, js, image folders'

task 'build', 'Build chocolate.js', (options) ->
  theme   = options.themes  or 'default'
  basedir = options.basedir or '/dist/' + theme
  current = path.dirname __filename

  dist = path.normalize current + '/dist/' + theme + '/'
  src  = path.normalize current + '/themes/' + theme + '/'

  fs.stat dist, (error, stat) ->
    if stat
      results = fs.readdirSync dist

      for folder in results
        folder = path.normalize dist + folder
        files  = fs.readdirSync folder
        if files and files.length > 0
          fs.unlinkSync path.normalize(folder + '/' + file) for file in files
        fs.rmdirSync folder

      fs.rmdirSync path.normalize dist

    fs.mkdirSync dist
    fs.mkdirSync dist + 'js'
    fs.mkdirSync dist + 'css'

    if fs.statSync src + 'images'
      fs.mkdirSync dist + 'images'
      images = fs.readdirSync src + 'images'
      for image in images
        from = fs.createReadStream path.normalize src + 'images/' + image
        to   = fs.createWriteStream path.normalize dist + 'images/' + image

        util.pump from, to

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
