module.exports = {
  // pipeline上下文, 所有插件的配置注册在这里 pipeline context, all plugins are registed here
  context: {},
  // 线上预览地址，代理配置相关 online preview address，proxy configuration related
  preview: {
    url: 'http://online.address',
  },
  // 文档 document：https://bytedance.feishu.cn/space/doc/doccnNddIs8naNrLieinHI?from=message
  // pipeline stages 配置 pipeline stages config
  stage: {
    install: {
      script: ['eden fastinstall --type yarn'],
    },
    build: {
      beforeScript: ['npm run generate-routes'],
      script: ['npm run build'],
    },
    upload: {
      beforeScript: [],
      script: [
        //
      ],
      afterScript: [
        'find ./build -name "*.js.map" | xargs rm -rf',
        'mkdir ../output_resource',
        'mkdir -p ../output/ios',
        'cp -r build/resource/* ../output_resource/',
        'cp -r build/template/* ../output_resource/',
        'cp -r build/template/pages/* ../output/ios',
        'node ./scripts/generate-search-json.js',
        'cp -r ios-develop-menus.json ../output/ios',
      ],
    },
  },
};
