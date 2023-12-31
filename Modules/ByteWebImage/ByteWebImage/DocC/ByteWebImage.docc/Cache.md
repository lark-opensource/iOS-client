# 缓存

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-cache.svg")
}

图片下载后的缓存机制，避免重复下载

## Overview

缓存模块主要围绕 ``ImageCache`` 实现，包含内存缓存和磁盘缓存。

内存缓存中会存储已经解码的图片 (``ByteImage`` 对象，本质是 `Bitmap`)。

磁盘缓存中会存储图片原始数据（Data 对象，本质是文件）。

### Default Implementation
### 默认实现

``ImageCache`` 主要由 ``ImageCache/diskCache`` 和 ``ImageCache/memoryCache`` 组成。

初始化方法 ``ImageCache/init(_:)`` 提供基于 `YYCache` 的磁盘缓存 ``DefaultImageDiskCache`` 和内存缓存 ``DefaultImageMemoryCache``。

### Customize Configuration
### 自定义配置

对于默认缓存，可以通过一些配置来进行简单的定制，参见 ``ImageCache/config``。

如果要单独配置磁盘或者内存缓存配置，参见磁盘缓存配置 ``DefaultImageDiskCache/config`` 与内存缓存配置 ``DefaultImageMemoryCache/config``。

### Integrate with ImageManager
### 与 ImageManager 集成

在基于 ImageManager 的一般图片请求流程中，常见的缓存流程是：

* 根据图片请求，先到相应缓存中的内存缓存中查询是否存在
  * 如果存在，直接返回
  * 如果没有，则会去查询磁盘缓存
    * 如果磁盘缓存存在，则会进行解码流程，存入内存缓存并返回
    * 如果磁盘缓存不存在，则会进行下载流程
      * 下载失败，直接返回下载错误
      * 下载成功，尝试解码，如果成功，则会尝试解码
        * 解码失败，直接返回错误，不缓存
        * 解码成功，存入磁盘缓存和内存缓存，并且返回图片

![图片加载流程](image-process.jpg)

### Fuzzy Query
### 模糊查询

模糊查询指查找同一图片的相似规格的图片，比如全尺寸分辨率的图片。

目前仅内存缓存支持模糊查询。

例如：查找降采样 100 \* 100的图片缓存时，可以返回 200 \* 200 的图片缓存，或 原图 缓存。

```swift
// 设置 支持模糊查询
let options: ImageRequestOption = [.fuzzy]
imageView.bt.setImage(url, options: options)
```

> Note: 对于后续的处理操作：
>
> 当存在裁剪（crop）时，则要求裁剪参数必须相同，或者查找到的是原图。当查找到原图时，会通过 Processor 进行重新处理。

### Customize Cache
### 自定义缓存

如果对缓存流程有特殊的要求，可以通过 ``ImageManager/registerCache(_:forKey:)`` 方法向 ``ImageManager`` 注册自定义下载器。注册之后，如果请求时在 ``ImageRequestOptions`` 中携带了 ``ImageRequestOption/cache(_:)``，则会使用对应的缓存。

要注册一个自定义下载器，需要提供内存和磁盘缓存的实现。内存缓存需要遵从 ``ImageMemoryCacheable`` 协议，磁盘缓存需要遵从 ``ImageDiskCacheable`` 协议。最终通过 ``ImageCache/init(_:memoryCache:diskCache:)`` 方法来初始化一个自定义的缓存。

注册的流程和使用示例：

```swift
// 构造自己的自定义缓存
let cache = ImageCache("customCache", memoryCache: customMemoryCache, diskCache: customDiskCache)

// 注册特定缓存(如果有重复的 identifier，默认行为是覆盖原有缓存，也即支持换绑)
ImageManager.default.registerCache(cache, forKey: identifier)

// 通过设置 ImageRequestOption 来使用指定缓存
let options: ImageRequestOption = [.cache("customCache")]
imageView.bt.setImage(url, options: options) // 通过 UIImageView 发起请求
ImageManager.default.requestImage(url, options: options) // 或者通过 ImageManager 发起请求
```

## Topics

### 缓存

- ``ImageCache``
- ``ImageDiskCacheable``
- ``ImageMemoryCacheable``
- ``DefaultImageDiskCache``
- ``DefaultImageMemoryCache``
- ``ImageRequestOption``

### 自定义缓存器

- ``ImageManager/registerCache(_:forKey:)``
- ``ImageRequestOption/cache(_:)``
