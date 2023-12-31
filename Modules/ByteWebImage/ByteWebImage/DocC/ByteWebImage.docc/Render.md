# 渲染

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-render.svg")
}

降采样、裁剪、动图播放、大图展示

## Overview

在解码的过程中，对于图片的渲染，图片库做了一些优化工作，以追求更好的性能和使用体验。

### Downsampling
### 降采样

通常，图片显示在屏幕上的实际大小，是小于图片本身的大小的。例如，一张 200 \* 200 的图片加载到一个 100 \* 100 的 `ImageView` 上，不会带来任何明显的好处，不仅会占用宝贵的内存，而且会因为额外的动态缩放而产生额外的性能开销。

当 `View` 的宽高比图片的宽高小很多的时候，在内存中加载较小的降采样 `Image` 来解码较大图片，可以避免不必要的内存和 CPU 消耗。（详见 WWDC 18 的 [Image and Graphics Best Practices](https://developer.apple.com/videos/play/wwdc2018/219)）

为了降低不必要的内存开销，防止加载大图导致内存占用过多（解码后的图片占用内存是非常多的，和图片的总像素数直接相关），图片库可以配置统一的默认最大总像素数限制 ``ImageManager/defaultDownsampleSize``。``ByteImage`` 初始化时会根据初始化方法参数 `downsampleSize` 来决定最大总像素限制，如果超过了最大限制，会自动将图片降采样到最大限制以下。

如果你有渲染清晰图片的需求，参见 <doc:Render#Huge-Image-Display>。

#### Animated Image Downsampling
#### 动图降采样

GIF 降采样涉及到的性能问题参见 <doc:Performance#GIF-Downsampling>。

> Experiment: 其他格式的动图降采样，需要通过 ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)`` 的初始化方法参数开启。

### Crop
### 裁剪

有的时候我们可能只需要一张图片的一部分，可以通过初始化 ``ByteImage`` 时，在初始化方法中给定 `cropRect` 来指定需要裁剪的部分。对于一个图片请求，暂时没有完善的配置支持，如果有需求可以提出。

> Note: 性能考量
>
> 对于 `JPG` 和 `HEIC` 数据格式的图片，由于 `ImageIO` 内部的支持，在实际裁剪中是不会渲染整张图片的，只会渲染指定的裁剪部分，这样有助于节省内存，优化性能。但是对于其他格式的图片，`ImageIO` 暂无优化。

### Animated Image Playing
### 动图播放

图片库对动图播放的优化主要围绕 ``ByteImageView`` 和 ``ByteImage`` 实现。

动图是很常见的元素。当直接使用 `UIImageView` 加载动图时，由于系统并没有提供动态加载图片帧的相关接口，我们不得不一次性将所有帧都加载进 `UIImageView`，导致需要一次性解码多张图片，内存占用大，性能也非常差。

如果你的业务 **可能** 需要加载动图，就应当将图片展示容器替换成 ``ByteImageView``，并且确保图片是 ``ByteImage`` 类型。

#### Performance Optimization
#### 性能优化

``ByteImageView`` 继承自 `UIImageView`，本身加入了动图的高性能优化，无其他副作用。业务方可以直接使用 `ByteImageView` 或者继承自 `ByteImageView`。

> Note: 动图的高性能优化：播放的整个过程中，不断加载当前帧和后一帧，并且丢弃已经播放过的帧，保持内存里只有当前帧和后一帧共两帧。

#### Supported Animated Image Formats
#### 支持的动图格式

图片库目前支持 ``ImageFileFormat/gif``、AWebP(Animated WebP)、APNG(Animated PNG)、``ImageFileFormat/heic`` 动图的播放。

#### High Frame Rate Protection
#### 高帧率保护

有的动图具有很高的帧率，对解码的压力（CPU 使用率）比较高。图片库做了以下两个优化：

1. 对于很多将帧长设为 0 以快速播放的广告动图，我们遵循 FireFox 和 [WebKit](http://webkit.org/b/36082) 的规范，如果动图的帧长小于 10ms，我们会主动将帧长调整到 100ms。
2. 动图下一帧不严格按照动图本身声明的时机，而是按实际性能情况播放。也即：动图下一帧的播放时机为：下一帧应该出现的播放时机 与 下一帧已经解码好的时机 二者最晚的时机。开始播放下一帧后，再开始解码下下帧。

### Huge Image Display
### 大图展示

对于超大的图片，我们可能需要在查看大图等场景下查看清晰版本的图片，在不能使用降采样的前提下保持内存使用总体可控。目前在 iOS 端达到这一点的主流方式即是分片加载。

分片加载基于 CATiledLayer & ImageIO 内置的分片解码实现(`UIImage/cropping(to:)`)。提供 ``HugeImageView`` 类供业务使用。

``HugeImageView`` 内部封装了 ``ByteImageView`` 和 ``TiledImageView``，同时提供普通大图、动图播放、分片渐进式加载的能力，有独立的（更大的）降采样限制阈值，适合查看大图场景使用。

```swift
let hugeImageView = HugeImageView()
// 设置图片数据
hugeImageView.setImage(data: data) { result in
    switch result {
    case .success:
        updateViewLayout(imageSize: imageView.imageSize)
        hugeImageView.updateTiledView(maxScale: self.scrollView.maximumZoomScale,
                                      minScale: self.scrollView.minimumZoomScale)
        print("display success, tiled: \(imageView.usingTile)")
    case .failure(let error):
        print(error)
    }
}
hugeImageView.reset() // 清空
```

> Note: 支持格式
>
> 目前由于性能表现的原因，分片加载暂时只支持 JPEG / HEIC 格式。如果不支持分片加载，会降级为降采样的图片展示。
>
> 对于常见的 PNG 格式，本身不支持分块解码，只支持顺序解码，ImageIO 内部也不支持；有替代方案是从上到下依次解码，及时回收内存（但是暂时还没测试过内存表现），分块做磁盘缓存，完毕之后再直接从磁盘读取分块缓存。这块工作量不小，一直没来得及测试性能表现和开发。
>
> 更多细节详见文档 [超大图预览现状及规划 - 飞书云文档](https://bytedance.feishu.cn/wiki/wikcniBYPHTc8UArxS3dpip5kZc)

> Tip: 为什么不推荐直接使用 `TiledImageView`
>
> ``TiledImageView`` 只包含单纯的分片展示，但是在加载的过程中，未加载的区域是没有任何预览的。
>
> 我们推荐在分片展示的同时，也生成一个模糊的缩略图作为下层背景图，防止在加载的过程中留出黑白底。
>
> 这就是 ``HugeImageView`` 做的事情，详见文档：
> * [iOS 大图分片优化方案设计 - 飞书云文档](https://bytedance.feishu.cn/wiki/wikcnHh9OibuPhY0MSxETlZXEVe)
> * [iOS 大图分片能力开放方案设计 - 飞书云文档](https://bytedance.feishu.cn/wiki/N4MhwN6cIiyoPsknFL5cR0jfnTh)

## Topics

### 降采样

- ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)``
- ``ImageManager/defaultDownsampleSize``
- ``ImageRequestOption``

### 动图播放

- ``ByteImageView``
- ``ByteImage``

### 分片加载

- ``HugeImageView``
