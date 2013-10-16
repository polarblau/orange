module.exports = (grunt)->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    concat:
      options:
        stripBanners: true
        banner: """
          ###
          <%= pkg.title || pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %>
          <%= pkg.homepage ? pkg.homepage : "" %>
          Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author %>
          Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %>
          ###
        """
      coffee:
        src: [
          'src/vendor/request_animation_frame.coffee'
          'src/orange.coffee'
          'src/orange/worker.coffee'
          'src/orange/utils.coffee'
          'src/orange/eventable.coffee'
          'src/orange/config.coffee'
          'src/orange/queue.coffee'
          'src/orange/job.coffee'
          'src/orange/batch.coffee'
          'src/orange/thread.coffee'
          'src/orange/scheduler.coffee'
        ]
        dest: 'dist/<%= pkg.name %>.coffee'

    strip_code:
      default:
        options:
          start_comment: 'test-only->'
          end_comment: '<-test-only'
        src: 'dist/<%= pkg.name %>.js'

    uglify:
      files:
        '<%= pkg.name %>.min.js': ['<banner:meta.banner>', '<config:concat.dist.dest>']

    coffee:
      compile:
        files:
          'test/all.js': [
            'test/unit/*.coffee'
            'test/acceptance/*.coffee'
          ]
          'test/fixtures/workers/sum.js': 'test/fixtures/workers/sum.coffee'
          'dist/<%= pkg.name %>.js': 'dist/<%= pkg.name %>.coffee'
          'dist/<%= pkg.name %>/worker.js': 'src/worker.coffee'
        options:
          sourceMap: true

    mocha_phantomjs:
      all: ['test/**/*.html']

    watch:
      default:
        files: ['src/**/*.coffee', 'test/**/*.coffee']
        tasks: ['test']

  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-mocha-phantomjs')
  grunt.loadNpmTasks('grunt-strip-code')

  grunt.registerTask('default', ['watch'])
  grunt.registerTask('test', ['concat:coffee', 'coffee:compile', 'mocha_phantomjs'])
  grunt.registerTask('build', ['test', 'strip_code', 'uglify'])
