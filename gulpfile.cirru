
var
  gulp $ require :gulp
  env $ or process.env.WEB_ENV :dev

switch env
  :min $ var
    config $ require :./webpack.min
  else $ var
    config $ require :./webpack.config

gulp.task :html $ \ ()
  var
    html $ require :gulp-cirru-html
    assets $ require :./assets.json
    data $ object
      :main $ + config.output.publicPath assets.main

  ... gulp
    src :./index.cirru
    pipe $ html $ object (:data data)
    pipe $ gulp.dest :./

gulp.task :coffee $ \ ()
  var
    coffee $ require :gulp-coffee
    rename $ require :gulp-rename

  ... gulp
    src :src/*.coffee (object (:base :src))
    pipe $ coffee (object (:dest :../lib) (:bare true))
    pipe $ rename (object (:extname :.js))
    pipe $ gulp.dest :./lib/

gulp.task :rsync $ \ (cb)
  var
    wrapper $ require :rsyncwrapper
  wrapper.rsync
    object
      :ssh true
      :src $ array :index.html :dist :examples
      :recursive true
      :args $ array :--verbose
      :dest :tiye:~/repo/cirru/script/
      :deleteAll true
    \ (error stdout stderr cmd)
      if (? error)
        do $ throw error
      if (? stderr)
        do $ console.error stderr
        do $ console.log cmd
      cb
