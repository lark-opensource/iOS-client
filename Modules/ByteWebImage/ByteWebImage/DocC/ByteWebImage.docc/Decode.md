# 解码

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-decode.svg")
}

从 `Data` 到 `UIImage/Bitmap`

## Overview

普通的图片生成，我们可以直接使用 `UIImage(data:)` 方法，从图片原始数据生成一张可以绘制、解码好的图片并且展示在屏幕上。

但是这样的方式并不能满足我们，最重要的原因是，`UIImage` 内部的解码流程是惰性解码的，默认会在图片第一次被贴上屏幕的时候进行解码和渲染。而图片被贴上屏幕是在主线程完成的，因此 `UIImage(data:)` 方法实际上会在主线程进行图片解码，这通常是比较耗时的，会造成卡顿问题。

> Tip: 更详细的讨论： [主流图片加载库所使用的预解码究竟干了什么](https://dreampiggy.com/2019/01/18/%E4%B8%BB%E6%B5%81%E5%9B%BE%E7%89%87%E5%8A%A0%E8%BD%BD%E5%BA%93%E6%89%80%E4%BD%BF%E7%94%A8%E7%9A%84%E9%A2%84%E8%A7%A3%E7%A0%81%E7%A9%B6%E7%AB%9F%E5%B9%B2%E4%BA%86%E4%BB%80%E4%B9%88/)

更重要的是，`UIImage(data:)` 底层会直接调用 `ImageIO` 解码库，没有拓展性，不能很好地支持新的格式。

因此，一般的图片库都会改造默认的懒解码流程，单独控制解码和渲染流程，这也是解码模块做的事情。

### Integrate with ImageManager
### 与 ImageManager 的集成

在基于 ImageManager 的一般图片请求流程中，涉及到的解码流程是：

* 如果在内存缓存中查询到，内存缓存是已经解码好的图片，不会再次解码。
* 如果在磁盘缓存中查询到，会先解码，再放入内存缓存，最后返回。
* 如果本地没有缓存，会在下载完成后解码，解码成功后放入磁盘和内存缓存，最后返回。

正常的图片请求流程中，解码流程也是在 ``ByteImage`` 的初始化方法 ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)`` 中进行。

### Supported Formats
### 格式支持

所有被支持的格式都会在 ``ImageFileFormat`` 中列举。

解码模块的解码能力支持主要由这些模块支持：

* WebP 格式，由 libwebp 支持
* 其他格式，由 ImageIO 支持

> Note: 用 libwebp 支持主要是为了支持 iOS 11/12 的 WebP 解码，并且 iOS 13 之后 ImageIO 也只是引入了 libwebp 进行解码，与直接调用没有区别。 

> Experiment: 为了更好的性能，HEIC 格式正在测试基于公司 `libttheif_ios` 库的解码

> Note: 暂时不支持 `RAW/DNG` 的识别，因为其与 `TIFF` 格式完全兼容，头部魔法数字一致。并且没有官方文档规定 `RAW/DNG` 或者 `Apple RAW/DNG` 的头部魔法数字的定义。

### Get Meta Info of Data or Image
### 图片元信息获取

图片文件数据主要分为元信息和图片数据本身两部分，其中图片数据需要经过耗时的解码才能展示在屏幕上。但是图片的元信息，其实在经过简单的处理之后，是可以直接读取，几乎不耗时的。

对于给定的 `Data`，我们提供这些接口来获取元信息：

元信息 | 接口 | 示例
--- | --- | ---
图片格式 | ``ImageWrapper/imageFileFormat-67ove`` | `data.bt.imageFileFormat`
图片数量（动图帧数） | ``ImageWrapper/imageCount`` | `data.bt.imageCount`
图片大小尺寸(px) | ``ImageWrapper/imageSize`` | `data.bt.imageSize`
是否是动图 | ``ImageWrapper/isAnimatedImage`` | `data.bt.isAnimatedImage`

> Tip:
> 如果你需要同时获取两种以上的属性，逐个调用上述接口可能会重复创建解码器对象。如果需要进一步提高性能，可以使用 ``ImageDecodeBox``。
>
> 类似于 `CGImageSource`，``ImageDecodeBox`` 通过一个 `data` 来初始化容器自身，初始化完成之后即可以从其属性中获取各种图片元信息。

对于已有的 `ByteImage`，我们提供这些接口来获取元信息：

元信息 | 接口 | 示例
--- | --- | ---
图片格式 | ``ImageWrapper/imageFileFormat-15ei`` | `byteImage.bt.imageFileFormat`
图片数量（动图帧数） | ``ByteImage/frameCount`` | `byteImage.frameCount`
图片大小尺寸(px) | `UIImage/pixelSize` | `uiImage.pixelSize`
是否是动图 | ``ByteImage/isAnimatedImage`` | `byteImage.bt.isAnimatedImage`

> Important: 动图判断方法
>
> 不能通过图片格式是否是 `GIF` 来判断是否是动图，因为动图可能有很多格式，`GIF` 也有可能只有一帧。应该通过 `isAnimatedImage` 相关接口来准确判断是否为动图。

### Pre-Decode
### 预解码

如前文所提到，图片库会单独控制解码和渲染的流程。预解码是默认打开的，默认会在初始化 ByteImage 的线程（通常是子线程）立即解码图片。

如果要关闭预解码，可以通过以下接口关闭：

* 如果是初始化 `ByteImage`，可以通过 ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)`` 接口初始化时，指定 `decodeForDisplay` 为 `false`
* 如果是图片请求，可以通过添加请求选项 ``ImageRequestOption/notDecodeForDisplay``

> Warning: 除非你很明确需要这么做，否则一般不推荐关闭预解码。关闭预解码会在 `UIImage` 添加在 `UIView` 的 layer 上时进入**系统**解码流程。

### Render
### 渲染

渲染部分的内容较多，详见 <doc:Render>。

### Customize Decoder
### 自定义解码器

如果需要自定义解码器，可以通过 ``ImageManager/register(_:_:)`` 来注册自定义解码器。

> Note: 如果需要添加新格式，需要明确格式的识别方法（数据头部魔法数字）、标志符(UTI)，并且联系图片库管理员添加对应格式。

## Topics

### 格式

- ``ImageFileFormat``
- ``ImageWrapper/imageFileFormat-67ove``
- ``ImageWrapper/imageFileFormat-15ei``
- ``ImageRequestOption``

### 预解码

关闭预解码的相关接口：

- ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)``
- ``ImageRequestOption/notDecodeForDisplay``

### 渲染

- <doc:Render>
