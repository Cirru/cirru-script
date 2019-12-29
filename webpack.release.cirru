
var
  path $ require :path
  webpack $ require :webpack
  AssetsPlugin $ require :assets-webpack-plugin
  webpackDev $ require :./webpack.dev
  DuplicatePackageCheckerPlugin $ require :duplicate-package-checker-webpack-plugin

-- ({}~ BundleAnalyzerPlugin) $ require :webpack-bundle-analyzer

= module.exports
  {}
    :mode :production
    :entry $ {}
      :main $ [] :./src/main

    :output $ {}
      :path $ path.join __dirname :dist/
      :filename :[name].[chunkhash:8].js

    :devtool :none

    :resolve webpackDev.resolve

    :module $ {}
      :rules $ []
        {} (:test /\.cirru$) (:loader :cirru-script-loader) (:exclude /node_modules)
        {} (:test /\.coffee$) (:exclude /node_modules)
          :use :coffee-loader
        {} (:test "/\.(png|jpg)$") (:loader :url-loader)
          :query $ {} (:limit 100)
        {} (:test /\.css$) $ :loaders $ [] :style-loader :css-loader
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
      new AssetsPlugin $ {}
        :filename :dist/assets.json
      new webpack.DefinePlugin $ {}
        :process.env $ {}
          :NODE_ENV $ JSON.stringify :production
      new DuplicatePackageCheckerPlugin
