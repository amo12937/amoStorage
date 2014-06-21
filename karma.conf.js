module.exports = function(config) {
  config.set({
    basePath: "",
    files: [
      "bower_components/angular/angular.js",
      "bower_components/angular-mocks/angular-mocks.js",
      "src/**/*.coffee",
      "test/**/*.coffee"
    ],
    frameworks: ["jasmine"],
    port: 8081,
    logLevel: config.LOG_INFO,
    autoWatch: false,
    browsers: ["PhantomJS"],
    preprocessors: {
      "src/**/*.coffee": "coffee",
      "test/**/*.coffee": "coffee"
    },
    reporters: ["spec"],
    runnerPort: 9100,
    singleRun: true
  });
};
