
fs = require('fs');

module.exports = {
  entry: {
    main: [
      'webpack-dev-server/client?http://0.0.0.0:8080',
      'webpack/hot/dev-server',
      './src/main'
    ]
  },
  output: {
    path: 'build/',
    filename: '[name].js',
    publicPath: 'http://localhost:8080/build/'
  },
  resolve: {
    extensions: ['', '.js', '.coffee']
  },
  module: {
    loaders: [
      {test: /\.coffee$/, loader: 'coffee'},
      {test: /\.css$/, loader: 'style!css'},
    ]
  },
  plugins: [
    function() {
       this.plugin('done', function(stats) {
        content = JSON.stringify(stats.toJson().assetsByChunkName, null, 2)
        return fs.writeFileSync('assets.json', content)
      })
    }
  ]
}
