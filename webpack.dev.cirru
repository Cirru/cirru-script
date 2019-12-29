
var
  fs $ require :fs
  path $ require :path
  webpack $ require :webpack

= module.exports
  {}
    :mode :development
    :entry $ {}
      :main $ [] :webpack-hud :./src/main

    :output $ {}
      :path $ path.join __dirname :dist/
      :filename :[name].js

    :devtool :cheap-source-map

    :resolve $ {}
      :extensions $ [] :.js :.cirru :.coffee :.json

    :module $ {}
      :rules $ []
        {} (:test /\.cirru$) (:exclude /node_modules)
          :use :cirru-script-loader
        {} (:test /\.coffee$) (:exclude /node_modules)
          :use :coffee-loader
        {} (:test "/\.(png|jpg|gif)$")
          :loader :url-loader
          :query $ {} (:limit 100)
        {} (:test /\.css$) $ :use
          []
            {} (:loader :style-loader)
            {} (:loader :css-loader)

    :devServer $ {}
      :publicPath :/
      :hot true
      :compress true
      :clientLogLevel :info
      :disableHostCheck true
      :host :0.0.0.0
      :stats $ {}
        :all false
        :colors true
        :errors true
        :errorDetails true
        :performance true
        :reasons true
        :timings true
        :warnings true

    :node $ {}
      :fs :empty
      :module :empty
      :net :empty

    :plugins $ []
      new webpack.NamedModulesPlugin
