
= gulp $ require :gulp
= env $ or process.env.WEB_ENV :dev

switch env
  :min $ = config $ require :./webpack.min
  else $ = config $ require :./webpack.config

gulp.task :html $ \ ()
  = html $ require :gulp-cirru-html

  = assets $ require :./assets.json
  = data $ object
    :main $ ++: config.output.publicPath assets.main

  ... gulp
    :src :./index.cirru
    :pipe $ html $ object (:data data)
    :pipe $ gulp.dest :./

gulp.task :coffee $ \ ()
  = coffee $ require :gulp-coffee
  = rename $ require :gulp-rename

  ... gulp
    :src :src/*.coffee (object (:base :src))
    :pipe $ coffee (object (:dest :../lib) (:bare true))
    :pipe $ rename (object (:extname :.js))
    :pipe $ gulp.dest :./lib/
