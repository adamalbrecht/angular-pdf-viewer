module.exports = (config) ->
  config.set
    autoWatch: true
    frameworks: ['jasmine']
    browsers: ['PhantomJS']
    preprocessors: {
      '**/*.coffee': ['coffee'],
    }
    coffeePreprocessor: {
      options: {
        bare: true,
        sourceMap: false
      }
      transformPath: (path) -> path.replace(/\.js$/, '.coffee')
    }
    reporters: ['progress', 'osx']
    files: [
      "vendor/bower/jquery/jquery.js"
      "vendor/bower/angular/angular.js"
      "vendor/bower/angular-mocks/angular-mocks.js"
      "src/**/*.coffee"
      "spec/**/*.coffee"
    ]
