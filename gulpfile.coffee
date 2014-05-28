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
less = require('gulp-less')

gulp.task "scripts", ->
  compiled = gulp.src("src/**/*.{coffee,js}")
    .pipe(gulpif(/[.]coffee$/,
      coffee({bare:true})
      .on('error', gutil.log)
    ))
    .pipe(ngmin())
  compiled
    .pipe(concat("src.js"))
    .pipe(gulp.dest("dist"))
  compiled
    .pipe(uglify())
    .pipe(concat("src.min.js"))
    .pipe(gulp.dest("dist"))

gulp.task "styles", ->
  compiled = gulp.src("src/**/*.{less,css}")
    .pipe(gulpif(/[.]less$/,
      less()
      .on('error', gutil.log)
    ))
  compiled
    .pipe(concat("style.css"))
    .pipe(gulp.dest("dist"))

  compiled
    .pipe(minifyCSS())
    .pipe(concat("style.min.css"))
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
