"use strict"

module.exports = (grunt) ->
  require("load-grunt-tasks") grunt
  require("time-grunt") grunt

  grunt.initConfig
    pkg: grunt.file.readJSON "bower.json"
    clean:
      dist: "src"
    coffee:
      options:
        sourceMap: true
        sourceRoot: ""
      dist:
        files: [
          {
            expand: true
            cwd: "coffee"
            src: "**/*.coffee"
            dest: "src"
            ext: ".js"
          }
        ]
    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= pkg.version %> | Copyright (c) <%= grunt.template.today('yyyy') %> Author: <%= pkg.authors %> | License: <%= pkg.license %> */"
      build:
        src: "src/<%= pkg.name %>.js"
        dest: "src/<%= pkg.name %>.min.js"
    karma:
      unit:
        configFile: "karma.conf.js"
        singleRun: true

  grunt.registerTask "build", [
    "clean:dist"
    "coffee:dist"
    "uglify"
  ]

  grunt.registerTask "test", [
    "karma:unit:start"
  ]

