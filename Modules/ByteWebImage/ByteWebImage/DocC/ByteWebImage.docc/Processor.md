# 处理

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-processor.svg")
}

获取图片后，返回之前，可以对图片做处理

## Overview

这个模块可以实现在下载图片后，存入缓存前，或者从缓存取得后，最终返回之前，对图片做的处理变换工作。

业务方可以实现 ``Processable`` 协议，并且在图片请求中传入 ``ImageRequestOption/transformer(_:)`` 来实现图片的预处理。

### Built-in Processor
### 内置的预处理器

库内置了一个圆角预处理器 ``RoundCornerTransformer``。

## Topics

### 预处理

- ``Processable``
- ``ImageRequestOption``

### 内置的预处理器

- ``RoundCornerTransformer``
