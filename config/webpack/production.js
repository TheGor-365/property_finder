process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const environment = require('./environment')

// Temporary compatibility with Node.js 22 / OpenSSL 3.
// Webpacker 5 bundles compression-webpack-plugin 4,
// which calls crypto.createHash('md4') on Webpack 4.
// Compression should be handled by the web server or CDN.
environment.plugins.delete('Compression')
environment.plugins.delete('Compression Brotli')

module.exports = environment.toWebpackConfig()
