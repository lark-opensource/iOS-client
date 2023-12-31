> 该目录下放置您的业务模块 。

如果您也想对业务模块之间进行分类管理。也可以在该目录下面建立子目录来管理。

运行命令可以创建一个标准的模块

``` 
EEScaffold module create -n <module name> 
``` 

一个模块包括以下内容：

```
├── DemoModule.podspec // 模块的配置文件，具体可以参考 [Podspec Syntax Reference](https://guides.cocoapods.org/syntax/podspec.html)
├── README.md // 模块说明文件
├── configurations // 模块配置文件
│   ├── BuildConfiguration.json //模块构建时需要的参数配置
│   └── i18n // 国际化文件 ，详细内容参考 https://docs.bytedance.net/doc/423ltNdcPSR34ODrqEmrxf
│       └── i18n.strings.yaml
├── jazzy.yaml // 文档生成配置文件 使用 jazzy方案  https://github.com/realm/jazzy
├── resources // 资源配置文件
│   └── Assets.xcassets // 图片资源配置，请按照Assets的方式存放在这里
│       └── Contents.json
└── src // 源码目录，请将源码放在这里
    ├── configurations // 该目录将会存放自动生成的一些文件，请不要修改下面的东西
    │   ├── Config.swift
    │   ├── I18n.swift
    │   └── Resources.swift
    └── replaceme.swift


```