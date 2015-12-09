
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
    extensions: ['', '.js', '.json', '.coffee']
  },
  module: {
    loaders: [
      {test: /\.coffee$/, loader: 'coffee'},
      {test: /\.css$/, loader: 'style!css'},
      {test: /\.json$/, loader: 'json'}
    ]
  },
  node: {
    fs: 'empty',
    module: 'empty',
    net: 'empty'
  },
  plugins: []
}
