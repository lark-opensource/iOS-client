# 下载

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-download.svg")
}

从 `ImageRequest/URL` 获取 `Data`

## Overview

对于图片的下载，主要围绕 ``Downloader`` 和 ``DownloadTask`` 实现。

库内置了基于 URLSession 的 http(s) 下载器 ``URLSessionDownloader``。也支持业务方注入自定义下载器。

下载器支持一些参数的配置，包括并发控制 ``Downloader/maxConcurrentTaskCount``、队列指定 ``Downloader/operationQueue`` 等。

> Experiment: 下载任务理论上也支持一些参数配置，包括超时设置、优先级设置等，需要开发工作暴露相关属性。

### Integrate with ImageManager
### 与 ImageManager 集成

在基于 ``ImageManager`` 的一般图片请求流程中，常见的下载流程是：

* 如果本地缓存中没有图片，`ImageManager` 就会根据请求选项在内部查询合适的下载器。
* 下载过程中，可以将下载进度回传给 ImageManager，也支持渐进式回传数据以支持渐进式加载图片。
* 下载完成后，可以根据 Downloader 的配置来确定是否要进行数据格式 ``Downloader/checkMimeType`` 和数据长度 ``Downloader/checkDataLength`` 的检验。最终，会把数据回传给 ImageManager，进行之后的流程。

### Progressive Download
### 渐进式加载

通过在图片下载的过程中就开始尝试加载已经下载的图片部分，达到逐步清晰的效果。需要服务端（原图片数据）支持渐进式加载。

通过设置 ``ImageRequest/minProgressNotificationInterval`` 调整回调频率。

### Customize Downloader
### 自定义下载器

如果需要自定义下载流程，可以通过 ``ImageManager/registerDownloader(_:forKey:)`` 方法向 ``ImageManager`` 注册自定义下载器。注册之后，如果请求时携带了 ``ImageRequestOption/downloader(_:)``，则会使用对应的下载器。

注册的流程和使用示例：

```swift
// 注册特定下载器
// @discardableResult 方法，可忽略返回值
// 返回值表示是否已注册过该 key，不支持换绑
let success = ImageManager.default.registerDownloader(downloader, forKey: identifier)

// 通过设置 ImageRequestOption 来使用指定下载器
let options: ImageRequestOption = [.downloader(identifier)]
imageView.bt.setImage(url, options: options) // 通过 UIImageView 发起请求
ImageManager.default.requestImage(url, options: options) // 或者通过 ImageManager 发起请求
```

## Topics

### 下载

- ``Downloader``
- ``DownloadTask``
- ``URLSessionDownloader``
- ``ImageRequestOption``

### 自定义下载器

- ``ImageManager/registerDownloader(_:forKey:)``
- ``ImageRequestOption/downloader(_:)``
