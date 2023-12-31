# ABR 视频播放自动码率切换控制


## 权限问题

iOS 组件为源码组件，pod install 安装时，需要 gtilab 仓库权限。
如果遇到 pod install 问题，请前往 https://code.byted.org/ttmp/abrmodule 申请权限。
注意不要在 bytebus 平台申请组件权限。


## 相关文档

**ABR 接入文档** https://bytedance.feishu.cn/docs/doccn7IRnYRpcJQIbJeKyZOQjFf

**视频播放ABR组件介绍**  https://bytedance.feishu.cn/docs/doccnf1SOENSsD5eI4VOFUirxcg

**ABR算法部分简介** https://bytedance.feishu.cn/docs/doccnHEWEQYkwa4mrfNSjTIy2Ff



## 目录结构

```
.
├── ABRInterface.podspec                    pod 描述文件
├── ABRModule.podspec                       pod 描述文件
├── CPPLINT.cfg                             cpplint 配置文件
├── LICENSE                                 
├── README.md
├── android                                 android 组件目录
│   ├── abr-api                                 android 组件， noSo
│   └── abr-native                              android 组件， onlySo
├── example                                 示例 app，将组件编译运行起来
│   ├── android                                 android 示例 app
│   └── ios                                     iOS 示例 app
├── gradlew                                 gradle 跳板文件，对接 bytebus
├── ios                                     iOS 组件目录
│   ├── ABRInterface                            iOS 组件 ABRInterface
│   └── ABRModule                               iOS 组件 ABRModule
└── sources                                 跨平台源代码
    ├── algorithms                              算法代码
    └── common                                  通用接口代码
```

