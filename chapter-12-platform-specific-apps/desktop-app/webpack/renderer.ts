import CopyPlugin from 'copy-webpack-plugin';
import path from 'path';
import webpack from 'webpack';

const dirname = process.cwd();
const config: webpack.Configuration = {

    target: 'web',
    mode: 'development',
    devtool: 'source-map',
    context: path.resolve(dirname, '.'),

    entry: {
        app: ['./src/renderer.tsx']
    },
    
    module: {
        rules: [
            {
                test: /\.(ts|tsx)$/,
                use: [{
                    loader: 'ts-loader',
                    options: {
                        onlyCompileBundledFiles: true,
                        configFile: '../tsconfig-renderer.json',
                    },
                }],
                exclude: /node_modules/
            }
        ]
    },
    
    resolve: {
        extensions: ['.ts', '.tsx', '.js']
    },

    experiments: {
        outputModule: true,
    },
    
    output: {
        path: path.resolve(dirname, './dist'),
        filename: '[name].bundle.js',
        module: true,
        clean: false,
    },
    
    optimization: {
        splitChunks: {
            cacheGroups: {
                vendor: {
                    chunks: 'initial',
                    name: 'vendor',
                    test: /node_modules/,
                    enforce: true
                },
            }
        }
    },

    plugins: [

        new CopyPlugin({
            patterns: [
                {
                    from: 'index.html',
                    to: path.resolve('dist'),
                },
                {
                    from: 'css',
                    to: path.resolve('dist'),
                },
            ]
        }),
    ]
}

export default config;
