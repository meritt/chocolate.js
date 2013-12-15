jsdom = require 'jsdom'

module.exports = (grunt) ->

  theme = grunt.option 'theme'
  theme = 'default' if not theme or typeof theme isnt 'string'

  basedir = grunt.option 'basedir'
  basedir = "/dist/#{theme}/images/" if not basedir or typeof basedir isnt 'string'

  dest = "dist/#{theme}"
  destjs = "#{dest}/js/chocolate.js"
  destcss = "#{dest}/css/chocolate.css"

  sources = [
    'src/init.coffee'
    'src/utils.coffee'
    'src/storage.coffee'
  ]

  sources.push 'src/plugins/session.coffee' unless grunt.option 'no-session'
  sources.push 'src/plugins/history.coffee' unless grunt.option 'no-history'
  sources.push 'src/plugins/touch.coffee' unless grunt.option 'no-touch'

  sources.push 'src/chocolate.coffee'

  grunt.registerTask 'chocolate', ->
    done = @async()

    grunt.log.write 'Including options and templates...'

    html = grunt.file.read "themes/#{theme}/templates.html"
    jsdom.env html, [], (error, window) ->
      output = {}

      [].forEach.call window.document.querySelectorAll('script'), (script) ->
        key = script.getAttribute 'id'
        return if not key

        lines = script.innerHTML.split "\n"
        content = ''
        for line in lines
          content += line.trim()

        output[key] = content.trim()

      window.close()

      options = grunt.file.read "themes/#{theme}/options.json"
      options = "var defaultOptions = #{options};"

      output = "var templates = #{JSON.stringify(output)};"

      source = grunt.file.read destjs

      tmpl = "<%= vendors %>\n\n(function(window, document) {\n\n<%= source %>\n\n})(window, document);"
      data =
        vendors: grunt.file.read 'vendors/classlist/classList.js'
        source: options + "\n\n" + output + "\n\n" + source

      grunt.file.write destjs, grunt.template.process tmpl, data: data
      grunt.log.write().ok()
      done()

  grunt.initConfig
    clean: [dest]

    coffee:
      options:
        join: true
        bare: true

      chocolate:
        src: sources
        dest: destjs

    uglify:
      compress:
        options: report: 'gzip'
        files: [
          src: destjs
          dest: "#{dest}/js/chocolate.min.js"
        ]

    less:
      chocolate:
        src: "themes/#{theme}/css/chocolate.less"
        dest: destcss

    autoprefixer:
      options: browsers: ['last 2 versions', 'ie 9']
      chocolate: src: destcss

    csso:
      compress:
        options: report: 'gzip'
        files: [
          src: destcss
          dest: "#{dest}/css/chocolate.min.css"
        ]

    replace:
      basedir:
        options:
          force: true
          variables: 'basedir': basedir

        files: [
          expand: true
          src: ["#{dest}/**/chocolate.*"]
        ]

    copy:
      images:
        files: [
          expand: true
          cwd: "themes/#{theme}/images/"
          src: ['**']
          dest: "#{dest}/images/"
          filter: 'isFile'
        ]

  require('matchdep').filter('grunt-*').forEach(grunt.loadNpmTasks)

  grunt.registerTask 'default', [
    'clean'
    'coffee'
    'chocolate'
    'less'
    'autoprefixer'
    'replace'
    'uglify'
    'csso'
    'copy'
  ]
