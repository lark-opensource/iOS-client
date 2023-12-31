# 接入指南

@Metadata {
    @PageKind(article)
    @PageImage(purpose: icon, source: "icon-migration.svg")
}

对于使用其他图片库的业务方的迁移指南

## Overview

本篇文章主要包括自定义下载器、自定义缓存的介绍和使用。也包括解码能力的接入介绍。

### 自定义下载器

如果业务方需要自定义下载流程或具体的下载流程，可以通过自定义下载器来满足需求。

具体的接入流程参见 <doc:Download#Customize-Downloader>。

### 自定义缓存

默认的缓存有一些自定义选项可供配置，参见 <doc:Cache#Customize-Configuration>。

如果业务方确实需要自定义缓存流程，可以通过自定义缓存器来满足需求。

具体的接入流程参见 <doc:Cache#Customize-Cache>。

### 解码能力接入

如果只想接入解码能力，可以用 `Data` 通过 ``ByteImage/init(_:scale:decodeForDisplay:downsampleSize:cropRect:enableAnimatedDownsample:)`` 方法初始化 ``ByteImage``。

> Important: 涉及到动图、大图，需要注意性能问题，参见<doc:Performance>文档

### 统计信息

> Experiment: 关于图片加载全流程的错误、耗时等信息，都可以通过注册 ``PerformanceMonitor/registerPlugin(_:)`` 来注册自定义的 ``PerformancePlugin``。对于所有经过 `setImage` 或者 `requestImage` 发起的<doc:ImageRequest>，在成功、失败、下载、解码都会有相应回调。可以通过访问 ``PerformanceRecorder`` 的属性来获得统计信息。
>
> ``PerformanceRecorder`` 的各种属性暂时未公开，如果有使用需求，可以提需求改造。
