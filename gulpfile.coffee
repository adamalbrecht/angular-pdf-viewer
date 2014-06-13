# Utilities
gulp = require("gulp")
gutil = require("gulp-util")
gulpif = require('gulp-if')
clean = require("gulp-clean")
concat = require("gulp-concat")
coffee = require("gulp-coffee")
uglify = require("gulp-uglify")
minifyCSS = require("gulp-minify-css")
ngmin = require("gulp-ngmin")
sass = require("gulp-ruby-sass")
notify = require("gulp-notify")
rename = require("gulp-rename")

packageFileName = 'my-package'

gulp.task "scripts", ->
  gulp.src("src/**/*.{coffee,js}")
    .pipe(gulpif(/[.]coffee$/,
      coffee({bare:true})
      .on('error', gutil.log)
    ))
    .pipe(ngmin())
    .pipe(concat("#{packageFileName}.js"))
    .pipe(gulp.dest("dist"))
    .pipe(uglify())
    .pipe(rename({extname: ".min.js"}))
    .pipe(gulp.dest("dist"))

gulp.task "styles", ->
  gulp.src("src/**/*.{scss,sass}")
    .pipe(sass({
        sourcemap: false,
        unixNewlines: true,
        style: 'nested',
        debugInfo: false,
        quiet: false,
        lineNumbers: true,
        bundleExec: true
      })
      .on('error', gutil.log))
      .on('error', notify.onError((error) ->
        return "SCSS Compilation Error: " + error.message;
      ))
    .pipe(rename("#{packageFileName}.css"))
    .pipe(gulp.dest("dist"))
    .pipe(minifyCSS())
    .pipe(rename({extname: ".min.css"}))
    .pipe(gulp.dest("dist"))

gulp.task "clean", ->
  return gulp.src(["dist"], {read: false})
    .pipe(clean({force: true}))

gulp.task 'watch', ->
  gulp.watch('src/*.*', ['scripts', 'styles'])

gulp.task "compile", ["clean"], ->
  gulp.start("scripts", "styles")

gulp.task "default", ["clean"], ->
  gulp.start("scripts", "styles", "watch")
