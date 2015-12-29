module.exports = {
    entry: './src/index.js',
    output : {
        filename: './static/bundle.js'
    },
    module: { },
    externals: { },
    resolve: {
        extensions: ['', '.js']
    },
    plugins: []
}
