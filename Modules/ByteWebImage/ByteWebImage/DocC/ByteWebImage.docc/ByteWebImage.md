# ``ByteWebImage``

@Options {
    @TopicsVisualStyle(detailedGrid)
}

Bytedance 自研的 Swift iOS 图片库

## Overview

ByteWebImage 图片库为业务提供了图片下载、图片缓存、解码渲染等基本能力。支持 iOS 11+ 系统。

库内置了基于 URLSession 的 http(s) 下载器；基于 YYCache 的内存/磁盘缓存器；基于 ImageIO 和 libwebp 的图片解码器。并且对外提供埋点、日志和耗时信息。

### A Typical Process of an Image Request
### 一个典型的图片请求流程

一个普通的``ImageRequest``流程主要包括：生成请求、查询缓存、下载、解码、存缓存、处理、返回、渲染这几个主要阶段。

![图片请求流程](image-process.jpg)

本文档也将图片库的所有功能，拆分成这些子功能并分别进行说明。

### DocC Writing Principles
### DocC 写作原则

* `Article` 只用来介绍关键 API 和讲述主流程，避免过多的细节和容易变更的内容。
* 内部实现、细节介绍应该和源代码放在一起，放在 API 接口说明中，方便维护和更改。
* 尽量避免使用 `Extensions`，如果必须使用，在相应结构的源代码中注释提醒，方便同步更改。
* `Tutorials` 只用来介绍复杂 API 的使用。

### Known Issues
### 已知问题

* 小标题英文: 主要是需要兼顾跳转章节，见[讨论](https://github.com/apple/swift-docc/issues/527)。

对于本文档有任何疑问，请直接联系 [@huanghaoting](https://applink.feishu.cn/client/chat/open?openId=ou_263ce62871adc8898386e712b509debf) [@kangsiwan](https://applink.feishu.cn/client/chat/open?openId=ou_cfdedb171040f183de7c479f24989aa9)。

## Topics

### 基本能力

- <doc:Download>
- <doc:Cache>
- <doc:Decode>
- <doc:Processor>
- <doc:Render>
- <doc:Performance>

### 使用

- <doc:Core-business>
- <doc:Lark-subspec>
- ``ImageRequest``

### 接入

- <doc:Migration>
