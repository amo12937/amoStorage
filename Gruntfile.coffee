"use strict"

module.exports = (grunt) ->
  require("load-grunt-tasks") grunt
  require("time-grunt") grunt

  grunt.initConfig
    karma:
      unit:
        configFile: "karma.conf.js"
        singleRun: true

  grunt.registerTask "test", [
    "karma:unit:start"
  ]

