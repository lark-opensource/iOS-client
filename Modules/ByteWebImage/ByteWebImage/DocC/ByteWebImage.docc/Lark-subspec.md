# Lark使用指南

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-lark-subspec.svg")
}

对于 Lark 业务方使用图片库，最关心的接口和问题

## Overview

Lark 封装资源类型、获取(Rust)图片、缓存、动图展示、预加载、上传图片

### LarkImageResource

Lark 中常用的图片类型包括：Rust 图片（加密图、非加密图）、头像（非加密）、Reaction、表情包。这些资源类型有固定的格式、场景和下载接口。为此，我们封装了 ``LarkImageResource``，业务方可以根据自身情况选择合适的资源类型，无需关心下载、缓存的细节。

### Request an Image
### 请求一张图片

从 ``LarkImageResource`` 获取一张图片最简单的方法即是通过 `setLarkImage` 或者 `LarkImageService.shared.setImage` 接口。

二者都包含了默认的缓存、下载流程（称之为<doc:ImageRequest>，详细的流程参见 <doc:ImageRequest#Image-Request-Process>），普通业务方无需关心。

如果需要改变这些默认行为，参见 ``ImageRequestOption``。

#### .bt.setLarkImage

```swift
let 图片容器 = "`ByteImageView/UIImageView` 或 `UIButton`"
```

如果你有一个图片容器，希望将 ``LarkImageResource`` 对应的图片设在上面，可以用下面这些方法：

| 对象 | 方法 |
| --- | --- |
| `UIImageView` | ``ImageWrapper/setLarkImage(with:placeholder:passThrough:options:transformer:downloaderIdentifier:size:cacheName:timeoutInterval:trackStart:trackEnd:modifier:file:function:line:progress:decrypt:completion:)`` | <!--推荐使用 | -->
| `UIButton` | ``ImageWrapper/setLarkImage(with:for:placeholder:passThrough:options:transformer:downloaderIdentifier:size:cacheName:timeoutInterval:trackStart:trackEnd:modifier:file:function:line:progress:decrypt:completion:)`` | <!--推荐使用 | -->
<!-- | | ``ImageWrapper/setLarkImage(_:placeholder:passThrough:options:trackInfo:modifier:file:function:line:callbacks:)`` | `options` 聚合了多个参数，但 `callbacks` 可能不便于使用，不推荐 |
| | ``ImageWrapper/setLarkImage(_:placeholder:passThrough:options:trackInfo:modifier:file:function:line:callbacks:)`` | 重构后的新方法，待观测稳定性，暂不推荐 |
| | ``ImageWrapper/setLarkImage(_:for:placeholder:passThrough:options:trackInfo:modifier:file:function:line:callbacks:)`` | `options` 聚合了多个参数，但 `callbacks` 可能不便于使用，不推荐 |
| | ``ImageWrapper/setLarkImage(_:for:placeholder:passThrough:options:transformer:downloaderIdentifier:size:cacheName:timeoutInterval:trackInfo:modifier:file:function:line:progress:decrypt:completion:)`` | 重构后的新方法，待观测稳定性，暂不推荐 | -->

使用示例：

```swift
let resource: LarkImageResource = .default(key: imageKey)
imageView.bt.setLarkImage(resource,
                          trackInfo: {
                          // 埋点信息，很重要，上层业务方都尽量传一传
                          // 会影响图片大盘统计数据和问题排查
                              TrackInfo(biz: .Messager,
                                        scene: .Chat,
                                        fromType: .image)
                          },
                          completion: { result in
                              switch result {
                              case .success(let result):
                                  print(result)
                              case .failure(let error):
                                  print(error)
                              }
                          })
```

请求成功时，返回的 result 中有一些属性可以获取更详细的信息，参见 ``ImageResult``。

> Important: 使用该接口需要注意时序问题，`setLarkImage` 和 `setImage` 的时序问题类似，参见<doc:Core-business#Timing-Issue>。

> Tip: 当请求成功时，`setImage` 接口内部会自动设置 `imageView.image`，不用手动设置。
>
> `setImage` 接口内部其实就是调用下面的 `LarkImageService.shared.setImage` 接口，只是最终会自动会自动设置图片到图片容器上。

> Tip: 失败时不用打印日志，图片库内部会有日志打印，只需要搜索 `load image failed & [Your file name]` 即可。

### LarkImageService

``LarkImageService`` 封装了 Lark 业务使用的图片请求、图片缓存、配置策略等逻辑，通常业务方关心的接口有这些：

#### LarkImageService.shared.setImage

如果你没有图片容器，只是想从 ``LarkImageResource`` 获取一张图片，那么你可以使用
``LarkImageService/setImage(with:passThrough:options:category:modifier:file:function:line:progress:decrypt:completion:)``。

```swift
LarkImageService.shared.setImage(with: resource, completion: { imageResult in
    switch imageResult {
    case .success(let result):
        print(result)
    case .failure(let error):
        print(error)
    }
})
```

> Note: 这里的 `placeholder` 参数脱离了图片容器，其实没有作用，待删除。

#### Lark Image Cache
#### Lark 的图片缓存

参见 ``LarkImageService`` 的缓存相关属性，可以实现查询图片是否存在于内存/磁盘中、从缓存中获取图片、将图片存入/移出缓存。

#### Lark Image Setting
#### Lark 的图片配置

图片库接入 Lark 时，有一些列的默认配置 ``LarkImageService/imageSetting``，包括：

配置 | 属性 | 配置值
--- | --- | ---
降采样配置，见 <doc:Render#Downsampling> | ``ImageManager/defaultDownsampleSize`` | 1000pt \* 1000pt

### ImagePassThough

> Note: 这个属性仅与 `RustPB/MGetResources` 接口相关。

有的时候我们需要获取一些 `RustSDK` 不感知 `fsUnit`、`crypto` 信息的图片，需要端上把相关信息直接带给服务端。这个时候就需要我们将相关字段通过 ``ImagePassThrough`` 透传。

``ImagePassThrough`` 与 `RustPB/Basic_V1_ImageSetPassThrough` 结构体等价，可以相互转换。

可以在发起图片请求时，在 `setLarkImage` 接口，或者 `LarkImageService.shared.setImage` 接口中传入 `passThough` 参数。

### Image Request Log & Tracker
### 图片请求的日志和埋点

图片库在 Lark 层加入了一些图片请求流程的日志和埋点。

对于日志，当加载失败时，可以通过日志搜索 `load image failed & [Your file name]` 找到加载失败的相关日志；当加载成功时，目前由于日志太频繁，对于从内存加载的图片请求，会按比例随机抛弃日志。磁盘和网络请求都会全量记录，不会抛弃。

对于（可感知）埋点，在 `setLarkImage` 接口中有内置的埋点，可以在 Tea 平台上查询 `appr_time_image_load` 和 `appr_error_image_load` 查询成功和失败的埋点，包括成功耗时、失败错误码等信息。当你传入准确的 ``TrackInfo`` 后，可以通过埋点过滤出你的场景。当加载失败时，全量的埋点都会上报；当加载成功时，目前由于埋点成本治理，对于从内存和磁盘加载的图片请求，会按比例抛弃埋点，网络请求会全量上报。

对于 `LarkImageService.shared.setLarkImage` 接口，暂时没有埋点的上报，因为不清楚业务方收到回调后的流程，不属于用户可感知耗时。

### Upload Image
### 上传图片

参见 <doc:Upload-Image-in-Lark>

### Q&A

### Difference between setImage & setLarkImage?
### setImage & setLarkImage 的区别？

接收参数不同，一个是 `URL`，一个是 ``LarkImageResource``。

## Topics

### 资源获取

- ``LarkImageResource``
- ``ImageRequestOption``
- ``ImageWrapper/setLarkImage(with:placeholder:passThrough:options:transformer:downloaderIdentifier:size:cacheName:timeoutInterval:trackStart:trackEnd:modifier:file:function:line:progress:decrypt:completion:)``
- ``ImageWrapper/setLarkImage(with:for:placeholder:passThrough:options:transformer:downloaderIdentifier:size:cacheName:timeoutInterval:trackStart:trackEnd:modifier:file:function:line:progress:decrypt:completion:)``
- ``ImageResult``

### LarkImageService

- ``LarkImageService``

### ImagePassThough

- ``ImagePassThrough``

### 上传图片

- <doc:Upload-Image-in-Lark>
