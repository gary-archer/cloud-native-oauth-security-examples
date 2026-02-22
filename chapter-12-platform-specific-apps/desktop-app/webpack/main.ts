import CopyPlugin from 'copy-webpack-plugin';
import path from 'path';
import webpack from 'webpack';

const dirname = process.cwd();
const config: webpack.Configuration = {

    target: 'electron-main',
    mode: 'development',
    devtool: 'source-map',
    context: path.resolve(dirname, '.'),

    entry: {
        app: ['./src/main.ts']
    },
    
    module: {
        rules: [
            {
                test: /\.ts$/,
                use: [{
                    loader: 'ts-loader',
                    options: {
                        onlyCompileBundledFiles: true,
                        configFile: '../tsconfig-main.json',
                    },
                }],
                exclude: /node_modules/
            }
        ]
    },
    
    resolve: {
        extensions: ['.ts', '.js']
    },
    
    experiments: {
        outputModule: true,
    },
    
    output: {
        path: path.resolve(dirname, './dist'),
        filename: 'main.bundle.js',
        module: true,
        clean: true,
    },

    plugins: [
    
        new CopyPlugin({
            patterns: [
                {
                    from: 'src/preload.js',
                    to: path.resolve('dist'),
                },
                {
                    from: 'package.json',
                    to: path.resolve('dist'),
                },
            ]
        }),
    ],
}

export default config;
