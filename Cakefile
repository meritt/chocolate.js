fs        = require 'fs'
path      = require 'path'
util      = require 'util'
{compile} = require 'coffee-script'
less      = require 'less'
uglify    = require 'uglify-js'
{cssmin}  = require 'cssmin'
jsdom     = require 'jsdom'

option '-t', '--themes [NAME]', 'theme for compiled chocolate code'
option '-b', '--basedir [DIR]', 'directory with css, js, image folders'

task 'build', 'Build chocolate.js', (options) ->
  theme   = options.themes  or 'default'
  basedir = options.basedir or "/dist/#{theme}"
  current = path.dirname __filename

  dist = path.normalize "#{current}/dist/#{theme}/"
  src  = path.normalize "#{current}/themes/#{theme}/"

  fs.stat dist, (error, stat) ->
    if stat
      results = fs.readdirSync dist

      for folder in results
        folder = path.normalize dist + folder
        files  = fs.readdirSync folder
        if files and files.length > 0
          fs.unlinkSync path.normalize "#{folder}/#{file}" for file in files
        fs.rmdirSync folder

      fs.rmdirSync path.normalize dist

    fs.mkdirSync dist
    fs.mkdirSync dist + 'js'
    fs.mkdirSync dist + 'css'

    if fs.statSync src + 'images'
      fs.mkdirSync dist + 'images'
      images = fs.readdirSync src + 'images'
      for image in images
        from = fs.createReadStream path.normalize "#{src}images/#{image}"
        to   = fs.createWriteStream path.normalize "#{dist}images/#{image}"

        util.pump from, to

    compileCssContent dist, src, basedir
    compileJsContent dist, src, basedir

compileTemplate = (src, basedir, fn) ->
  html = fs.readFileSync "#{src}templates.html", 'utf8'
  jsdom.env html, ['http://ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js'], (error, window) ->
    templates = {}

    $ = window.$
    $('script').each ->
      key = $(@).attr('id')

      if key
        html = $(@).html()
        html = html.replace /\{\{basedir\}\}/gi, basedir

        lines = html.split "\n"
        html  = ''
        for line in lines
          line = $.trim line
          html += line if line isnt ''

        templates[key] = $.trim html

    window.close()
    fn templates

compileJsContent = (dist, src, basedir) ->
  current = path.dirname __filename
  source  = path.normalize "#{current}/src/chocolate.coffee"

  options = "defaultOptions = `" + fs.readFileSync(src + 'options.json', 'utf8') + "`"

  compileTemplate src, basedir, (templates) ->
    templates = "templates = `" + JSON.stringify(templates) + "`"

    chocolate = fs.readFileSync source, 'utf8'

    js = compile "#{options}\n\n#{templates}\n\n#{chocolate}", bare: true
    js = "(function(window, document) {\n\n#{js}\n\n})(window, document);"

    fs.writeFileSync path.normalize(dist + 'js/chocolate.js'), js

    source = uglify.minify js, fromString: true
    source = source.code

    fs.writeFileSync path.normalize(dist + 'js/chocolate.min.js'), source

    console.log 'done'

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