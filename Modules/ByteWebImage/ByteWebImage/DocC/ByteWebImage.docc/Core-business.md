# 业务使用指南

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-core-business.svg")
}

对于普通业务方使用图片库，最关心的接口和问题

## Overview

获取图片、缓存、动图展示、预加载

### Request an Image
### 请求一张图片

从 `URL` 获取一张图片最简单的方法即是通过 `setImage` 或者 `requestImage` 接口。

二者都包含了默认的缓存、下载流程（称之为<doc:ImageRequest>，详细的流程参见 <doc:ImageRequest#Image-Request-Process>），普通业务方无需关心。

如果需要改变这些默认行为，参见 ``ImageRequestOption``。

#### .bt.setImage

```swift
let 图片容器 = "`ByteImageView/UIImageView` 或 `UIButton`"
```

如果你有一个图片容器，希望将 `URL` 对应的图片设在上面，可以用下面这些方法：

| 对象 | 方法 |
| --- | --- |
| `UIImageView` | ``ImageWrapper/setImage(_:alternativeURLs:placeholder:options:progress:decrypt:completionHandler:)`` |
| `UIButton` | ``ImageWrapper/setImage(_:for:alternativeURLs:placeholder:options:progress:decrypt:completionHandler:)`` |

使用示例：

```swift
imageView.bt.setImage(url, completionHandler: { imageResult in
    switch imageResult {
    case .success(let result):
        print(result)
    case .failure(let error):
        print(error)
})
```

请求成功时，返回的 result 中有一些属性可以获取更详细的信息，参见 ``ImageResult``。

> Important: 使用该接口需要注意时序问题，参见<doc:Core-business#Timing-Issue>。

> Tip: 当请求成功时，`setImage` 接口内部会自动设置 `imageView.image`，不用手动设置。
>
> `setImage` 接口内部其实就是调用下面的 `requestImage` 接口，只是最终会自动会自动设置图片到图片容器上。

#### ImageManager.default.requestImage

如果你没有图片容器，只是想从 `URL` 获取一张图片，那么你可以使用 ``ImageManager/requestImage(_:alternativeURLs:category:options:decrypt:progress:completion:)``。

```swift
ImageManager.default.requestImage(url, completion: { imageResult in
    switch imageResult {
    case .success(let result):
        print(result)
    case .failure(let error):
        print(error)
}
})
```

请求成功时，返回的 result 中有一些属性可以获取更详细的信息，参见 ``ImageResult``。

### Timing Issue
### 时序问题

如果你的图片容器涉及到了重用，那么在使用 `setImage` 接口需要特别注意时序问题。因为 `setImage` 内部是异步设置图片（可能需要等待磁盘解码，甚至网络下载之后才会设置图片）。

我们建议对于一个图片容器，设置图片时都通过 `setImage` 接口来设置。`setImage` 接口内部会保证时序（发起新请求之前，先取消旧请求）。

#### Cancel Image Request/Clear Image
#### 取消图片请求/清空图片

如果你需要重置一个图片容器，例如在回收准备重用的时候，可以通过 ``ImageWrapper/cancelImageRequest()`` 或者 ``ImageWrapper/cancelImageRequest(for:)`` 来取消当前正在进行中的图片请求。

```swift
func prepareForReuse() {
cell.imageView.bt.cancelImageRequest()
cell.uiButton.bt.cancelImageRequest(for: .normal)
}
```

你也可以通过 ``ImageWrapper/setImage(_:)`` 或者 ``ImageWrapper/setImage(_:for:)`` 接口，并且将参数 `image` 设为 `nil` 来清空图片请求的同时，清空图片容器上已经存在的图片。

```swift
func prepareForReuse() {
cell.imageView.bt.setImage(nil)
cell.uiButton.bt.setImage(nil, for: .normal)
}
```

#### Set a Local Image
#### 设置一张本地图片

如果你的图片容器既可能是网络图片，需要通过 `setImage` 接口拉取，也有可能是本地图片，需要将 `UIImage` 直接设置在图片容器上，可以在设置 `UIImage` 的时候使用 ``ImageWrapper/setImage(_:)`` 或者 ``ImageWrapper/setImage(_:for:)`` 接口，接口内部会先取消正在进行中的请求，再设置图片，保证时序安全。

```swift
func setImage() {
if local, let localImage {
cell.imageView.bt.setImage(localImage)
cell.uiButton.bt.setImage(localImage, for: .normal)
} else if remote, let remoteURL {
cell.imageView.bt.setImage(with: remoteURL)
cell.uiButton.bt.setImage(with: remoteURL, for: .normal)
} else { // 如果都不是，清空图片并且清空可能正在进行的请求
cell.imageView.bt.setImage(nil)
cell.uiButton.bt.setImage(nil, for: .normal)
}
}
```

### Init Image from Data
### 从 Data 初始化图片

如果你已经有图片数据 `Data` 了，需要初始化一个图片，你可以使用 ``ByteImage``。

> Important: `ByteImage` 初始化时默认会立即解码，强烈建议在子线程解码，详见 <doc:Decode#Pre-Decode>。

``ByteImage`` 支持的格式见 <doc:Decode#Supported-Formats>。

如果涉及到大图，参见 <doc:Render#Downsampling>。

如果涉及到动图展示，参见 <doc:Render#Animated-Image-Playing>。

### About Cache
### 关于缓存

如果你使用的是默认缓存，则可以通过 ``ImageCache`` 的属性 ``ImageCache/default`` 获得默认缓存实例。

如果你想查询一个 ``ImageCache/Key`` 是否在缓存中，可以通过方法 ``ImageCache/contains(_:options:fuzzy:)`` 查询。

### Animated Image
### 动图

如果涉及到动图展示，参见 <doc:Render#Animated-Image-Playing>。

如果遇到了加载失败的情况，

### Pre-Loading
### 预加载

如果你想提前下载图片，在需要的时候展示，可以使用 ``ImageManager/prefetchImage(_:category:options:)`` 或者 ``ImageManager/prefetchImages(_:category:options:)`` 来提前下载图片。和普通图片获取请求的主要区别在于：

1. 低优先级。如果有大量的预加载请求，在下载队列中不会阻塞正常的图片请求。
2. 仅下载存磁盘，不会预解码和存入内存缓存，避免影响性能。需要的时候再发起正常的图片请求。

这个接口的作用相当于<doc:ImageRequest>：`options: [.priority(.low), .ignoreImage]`。也即，你可以使用 `setImage` 或者 `requestImage` 接口，附上这些选项来达到相同的预加载效果。

## Topics

### 请求一张图片

- ``ImageRequest``
- ``ImageRequestOption``
- ``ImageWrapper/setImage(with:alternativeURLs:placeholder:transformer:downloaderIdentifier:size:options:cacheName:timeoutInterval:progress:decrypt:completionHandler:)``
- ``ImageWrapper/setImage(with:for:alternativeURLs:placeholder:transformer:downloaderIdentifier:size:options:cacheName:timeoutInterval:progress:decrypt:completionHandler:)``
- ``ImageResult``

### 时序问题

- ``ImageWrapper/cancelImageRequest()``
- ``ImageWrapper/cancelImageRequest(for:)``
- ``ImageWrapper/setImage(_:)``
- ``ImageWrapper/setImage(_:for:)``

### 从 Data 初始化图片

- ``ByteImage``
- <doc:Decode>
- <doc:Render>

### 关于缓存

- ``ImageCache``
- ``ImageCache/contains(_:options:fuzzy:)``

### 动图

- <doc:Render>

### 预加载

- ``ImageManager/prefetchImage(_:category:options:)``
- ``ImageManager/prefetchImages(_:category:options:)``
- ``ImageRequestOption/priority(_:)``
- ``ImageRequestOption/ignoreImage``
