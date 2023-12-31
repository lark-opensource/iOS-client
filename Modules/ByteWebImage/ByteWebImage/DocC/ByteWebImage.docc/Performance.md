# 性能

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-performance.svg")
}

耗时、内存使用和稳定性问题

## Overview

图片库在耗时和诸多稳定性问题，如内存使用、崩溃防护等有着诸多的工作。

### Time Performance
### 耗时表现

一次图片请求可能涉及到多个耗时流程，如下载耗时、缓存耗时、解码耗时，参见``ImageRequest``的文档。

### Memory Usage - Prevent OOM
### 内存使用 - 防止 OOM

图片库主要在这些方面控制内存的使用，避免 OOM：

1. 解码时默认限制最大分辨率，由 ``ImageManager/defaultDownsampleSize`` 控制，参见 <doc:Render#Downsampling>。
如果需要加载超大清晰图片，推荐使用大图展示容器，参见 <doc:Render#Huge-Image-Display>。
2. 缓存默认在 `didReceiveMemoryWarning(_:)` 时，清除所有对 `ByteImage` 的引用。
3. 以 ``ByteImageView`` 和 ``ByteImage`` 实现的动图播放懒加载：不加载所有帧，只加载当前帧和下一帧，参见 <doc:Render#Animated-Image-Playing>。

已知的潜在的内存问题：

1. GIF 降采样问题，参见 <doc:Performance#GIF-Downsampling>。
2. 超大图片文件，解码图片时会把整个文件加载到内存中。如果图片文件本身就很大，建议做前置判断，过大的图片文件不解码。

### GIF Downsampling
### GIF 降采样

GIF 由于其自身的编码问题，无法像其他格式一样，在解析出完整图片之前获取缩略图。因此，如果要想降采样一张 GIF，我们不得不先将 GIF 原始的图片渲染好，再进行降采样。对于降低内存而言，GIF 降采样是毫无意义的。

图片库提供配置 ``ImageManager/skipDecodeGIFMemoryFactor``，以在内存不足时拒绝解码过大的 GIF。

> Tip: 目前主要通过源头管控来避免加载过大的 GIF。建议加载的 GIF 宽高尺寸乘积不要超过 2000px \* 2000px。

### Known Issues
### 已知问题

这里列举一些目前已知，并且暂时无法解决的一些稳定性问题。

#### Decode Crash When App is Being Killing in Background
#### 后台杀进程时解码崩溃

通过线上监控可以发现，App 在后台被用户手动结束的时刻，如果通过 `ImageIO` 的相关接口读取图片的元数据（并不是对图片数据的解码，只是读取基本信息，如宽高），会导致崩溃。这个问题目前是用户无感知的，暂时没有很好的修复方案，若有好的方案欢迎讨论。参见文档 [⁡⁤⁤‍⁡⁣‌﻿⁤‬‬​﻿⁢⁣⁡‍​﻿​‬‌​​​‍﻿​​​‬⁢​⁡​⁤​⁢⁣⁣⁣⁤⁤​⁣‌﻿⁤﻿20221011 - 图片后台解码崩溃问题 - 飞书云文档](https://bytedance.feishu.cn/wiki/wikcnTfRA038xNbKuNGzucE8Mhd)

#### Decode GIF Crash When Memory Not Enough
#### 内存不足时解码 GIF 崩溃

ImageIO GIFReadPlugin 底层分配内存时，在 malloc 之后，并没有判断是否分配成功，就进行了memcpy，导致了 bad access。

这种情况通常是在 App 内存水位较高时，继续向系统申请大量空间，malloc 可能会失败。

而同时解码多张 GIF 非常容易占用较多内存，造成同时解码多张 GIF 容易 Crash 的现象（实际测试，给每张 GIF 加锁解码，仍然会 Crash）。若有好的方案欢迎讨论。参见文档 [‍⁡‌⁣⁤‍⁤⁤⁤‌⁢‬⁤⁢⁢⁡​⁤⁤﻿​‬﻿⁣‬​⁤﻿​⁤​⁣​‬⁣⁡⁡‌​‍​‍‬⁡⁣⁡⁡⁢‌⁤20220323 - iOS 高内存时解码 GIF 崩溃问题 - 飞书云文档](https://bytedance.feishu.cn/wiki/wikcnFKYWhoIDQgE2q5qLJlLeCf)

## Topics

### 相关文档

- <doc:ImageRequest>
- <doc:Render>
