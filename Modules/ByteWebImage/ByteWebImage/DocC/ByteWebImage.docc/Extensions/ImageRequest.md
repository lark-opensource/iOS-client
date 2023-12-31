# ``ByteWebImage/ImageRequest``

@Metadata {
    @DisplayName("图片请求")
    @PageImage(purpose: icon, source: "icon-image-request.svg")
}

## Overview

一次图片请求流程包括从使用方用 `URL` 初始化一个 `ImageRequest` 开始，`request` 被传递给 ``ImageManager`` 之后，进行的一系列流程。

对于一个图片请求，可以在初始化时传递 ``ImageRequestOption`` 来改变默认的行为。

在请求结束后，可以通过下面的一些属性获得相关的耗时统计信息。

### Image Request Process
### 图片请求流程

一次典型的图片请求如图所示：

![图片请求流程](image-process.jpg)

图中涉及到的模块内部细节可以参考文档<doc:Cache>、<doc:Decode>、<doc:Download>。

如果想在图片请求结束后，返回之前对图片做一些转换处理，参考文档<doc:Processor>。

## Topics

### 图片请求选项

图片请求本身有很多默认的行为，比如存缓存、解码返回，如果想改变这些行为，可以尝试在图片请求中设置图片请求选项

- ``ImageRequestOption``

### 耗时统计

`ImageRequest` 结束后，一些子阶段耗时统计可以在这些字段统计到：

- ``ImageRequest/cacheSeekCost``
- ``ImageRequest/queueCost``
- ``ImageRequest/downloadCost``
- ``ImageRequest/decryptCost``
- ``ImageRequest/decodeCost``
- ``ImageRequest/cacheCost``
