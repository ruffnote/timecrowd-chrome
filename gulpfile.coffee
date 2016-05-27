gulp = require 'gulp'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
postcss = require 'gulp-postcss'
scss = require 'postcss-scss'
plumber = require 'gulp-plumber'
uglify = require 'gulp-uglify'
zip = require 'gulp-zip'
del = require 'del'
gutil = require 'gulp-util'
rename = require 'gulp-rename'
jeditor = require 'gulp-json-editor'
fs = require 'fs'

gulp.task 'default', ['watch']

isProduction = gutil.env.production?
isStaging = gutil.env.staging?
isDeploy = isProduction || isStaging
envName = 'development'
envName = 'production' if isProduction
envName = 'staging' if isStaging

gulp.task 'zip', ['lint', 'coffee', 'manifest', 'img'], ->
  gulp.src 'app/**/*'
    .pipe zip("timecrowd-#{envName}.zip")
    .pipe(gulp.dest('./build'))

gulp.task 'coffee', ['env'], ->
  gulp.src './src/coffee/*.coffee'
    .pipe plumber()
    .pipe coffee()
    .pipe if isDeploy then uglify(preserveComments: 'some') else gutil.noop()
    .pipe gulp.dest('./app/js')

gulp.task 'scss', ['env'], ->
  processors = []
  gulp.src './src/scss/*.scss'
    .pipe postcss(processors, {syntax: scss})
    .pipe gulp.dest('./app/css')

gulp.task 'lint', ->
  gulp.src './src/coffee/*.coffee'
    .pipe coffeelint()
    .pipe coffeelint.reporter()

gulp.task 'watch', ['lint', 'coffee', 'scss', 'manifest', 'img'], ->
  gulp.watch 'src/coffee/*.coffee', ['coffee']
  gulp.watch 'src/scss/*.scss', ['scss']

gulp.task 'manifest', ->
  bumpVersion() if isProduction
  gulp.src './src/manifest.json'
    .pipe jeditor (json) ->
      delete json.key if isDeploy
      json.name += " (Dev)" unless isDeploy
      json.name = "__MSG_extNameStaging__" if isStaging
      json.version = readVersion()
      json
    .pipe gulp.dest('./app')

gulp.task 'img', ->
  gulp.src "./src/img/#{envName}/*"
    .pipe gulp.dest('./app/img')

gulp.task 'env', ->
  gulp.src "./src/env/#{envName}.coffee"
    .pipe rename('env.js')
    .pipe coffee()
    .pipe uglify(preserveComments: 'some')
    .pipe gulp.dest('./app/js')

gulp.task 'clean', del.bind(null, ['./app/js/*', './app/manifest.json', './build/*', './app/img/*'])

readVersion = ->
  fs.readFileSync('./src/version', 'UTF-8').replace(/\s/, '')

bumpVersion = ->
  versions = readVersion().split('.')
  versions[2] = parseInt(versions[2]) + 1
  fs.writeFileSync('./src/version', versions.join('.'))
