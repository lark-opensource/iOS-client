const createEdenConfig = require('@ies/create-eden-config');
const path = require('path');

const CDN_DOMAIN = '//cdn-tos-cn.bytedance.net/obj/archi';
const CDN_PREFIX = '/ee/es-design-ios';
const IsDev = process.env.NODE_ENV !== 'production';

function buildConfig() {
  const baseConfig = {
    ico: '//cdn-tos-cn.bytedance.net/obj/archi/ee/sce/activity/ico/favicon.ico',
    localhost: 'http://localhost:5007/develop/iOS',
    dist: 'build',
  };

  const devConfig = {
    publicPath: '/static/',
    NODE_ENV: 'development',
  };

  const prdConfig = {
    publicPath: `${CDN_DOMAIN}${CDN_PREFIX}/`,
    NODE_ENV: 'production',
  };

  return Object.assign(
    {
      staticPort: 5007,
      serverPort: parseInt(process.env.PORT || 3000),
      slardarVersion: '', // execSync('git rev-parse HEAD').toString().trim()
    },
    baseConfig,
    IsDev ? devConfig : prdConfig
  );
}

const config = buildConfig();

module.exports = createEdenConfig({
  // 将projectType设置为“ static”，Webpack开发服务器将在启用HMR的情况下启动
  // With projectType set `static`, Webpack dev server will be started with HMR enabled
  projectType: 'static',

  // 为每个条目定制preEntry，通常用于polyfills
  // Customize preEntry for every entry, commonly used for polyfills
  // preEntry: './src/utils/polyfill.js',

  // 自定义你的publicPaths Customize your publicPaths
  output: {
    publicPath() {
      return config.publicPath;
    },
  },

  resolve: {
    alias: {
      // 使用htmlparser2, 不让标签名和属性名全转换成小写
      'html-dom-parser': path.resolve(__dirname, './node_modules/html-dom-parser/lib/html-to-dom-server.js'),
    },
  },

  // 定义abilities Define abilities
  abilities: {
    checkes6: false,
    // dll中定义的包将被打包到dll.js中
    // Packages defined in dll will be bundled into dll.js
    // dll: ['react', 'react-dom'],
    react: true,
    less: {
      lessLoader: {
        lessOptions: {
          modifyVars: {
            '@theme-css-variable-enabled': 'true',
          },
          javascriptEnabled: true,
        },
      },
    },
    ts: {
      babel: true,
    },
    babel: {
      include: [
        // 进行babel转换时，将包含与此处定义的正则匹配的文件
        // Files match RegExps defined here will be included while babel transpiling
      ],
    },
    pages: {
      jsx: true,
      // match: /^page$/,
      recursion: false,
    },
    define: {
      'process.env.NODE_ENV': JSON.stringify(config.NODE_ENV),
    },
  },

  /**
   * 可以修改webpack或者rollup的options You can modify options of Webpack or Rollup
   * @param {object} options wepack 或者 rollup的选项 Options for Webpack or Rollup
   * @param {object} context 仅对rollup有效，该对象仅仅包含一个{ format }属性，定义输出格式 Only available for Rollup, it's an object with only one property { format }, defines output format
   * @returns {object} 选项将传递到Webpack或Rollup Options will be passed to Webpack or Rollup
   */
  raw(options) {
    options.module.rules.push({
      test: /\.md$/,
      use: [
        {
          loader: 'raw-loader',
        },
        {
          loader: path.resolve(__dirname, './md-loader'),
          options: {
            demoDir: 'demo',
          },
        },
      ],
    });

    // eslint-disable-next-line no-restricted-syntax
    for (const rule of options.module.rules) {
      if (Array.isArray(rule.use)) {
        rule.use.forEach(useLoader => {
          if ('/\\.less$/' === rule.test.toString() && /less-loader/.test(useLoader.loader)) {
            // 使用 workspace 里面的 less-loader
            useLoader.loader = require.resolve('less-loader');
            const { importer, ...lessOptions } = useLoader.options;
            useLoader.options = {
              ...lessOptions,
            };
          }
        });
      }
    }

    return options;
  },

  other: {
    writeToDisk: true,
  },

  // dev 开发工具 Dev develop tools
  dev: {
    port: config.staticPort,
    // 自动打开浏览器 Dev develop tools
    openBrowser: {
      enabled: true,
      url: config.localhost,
    },

    devServerHistoryApiFallback: {
      rewrites: [
        {
          from: /^\/develop\/iOS\/(.*)/,
          to: '/static/pages/components/index.html',
        },
        {
          from: /^\/develop\/iOS$/,
          to: '/static/pages/components/index.html',
        },
      ],
    },

    // proxy的配置，打开http://localhost:15323可以查看浏览器控制台
    // Configurations for proxy, open http://localhost:15323 for proxy console
    proxy: {
      // url改写 Url rewrite rules
      // See https://eden.bytedance.net/docs/configuration/url-rewrite
      urlRewrite: {},
    },
  },
});
