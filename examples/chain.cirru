
... gulp
  src :src/**/*.cirru (object (:base :src))
  pipe $ script (object (:dest :../lib))
  pipe $ rename (object (:extname :.js))
  pipe $ gulp.dest :./lib
