# BDWebImage

## 为了便于更新和分享，文档迁到[用户文档](https://bytedance.feishu.cn/space/doc/doccnhFMhmVMwFLdTNeAPZ) 2019.04.10

## 简介

BDWebImage 是一个异步图片加载框架。

其设计目的是试图替代 SDWebImage，YYWebImage，FLAnimatedImage等开源框架，它集合了这些开源框架的大部分必要功能，同时针对以上开源框架在性能和功能方面的不足进行了一定的提升。

## 特性

* UIImageView，UIButton 的 Category 方法支持，使用方便
* 异步图片加载
* 不阻塞主线程
* 高性能的内存和磁盘缓存
* 支持 GIF 动画，（动态缓存，低内存占用
* 支持动图边下边播
* 支持 webp 格式，为 iOS11 以下的系统提供 HEIC 格式支持
* 多种图片下载方式（NSURLSession，Chromium）
* 内置常用的图片处理
* 提供对图片下载耗时，解码耗时的监控
* 保证相同的 URL 不会被多次下载
* 保证无效的 URL 不会一次又一次地重试

## 现有组件对比

| Results | SDWebImage | HTSWebImage | YYWebImage | BDWebImage |
| --- | --- | --- | --- | --- |
| webp | ✅ | ✅ | ✅ | ✅ |
| heic | ✅ | ✅ | ❌ | ✅ |
| gif | ❌ | ❌ | ✅ | ✅ |
| transform | ❌ | ✅ | ✅ | ✅ |
| GIF边下边播 | ❌ | ❌ | ❌ | ✅ |
| monitor | ❌ | ✅ | ❌ | ✅ |
| Download | NSURLSession | NSURLSession | NSURLConnection | NSURLSession/Chromium |

## 版本要求

+ iOS 
+ Xcode版本：

## 运行Example工程

+ clone工程
+ 切换到`Example`目录
+ `pod install`
+ 到`BDViewController`中的`- viewDidLoad:`切换测试功能

## 接入方式

CocoaPods接入方式支持：

+ [x] 源码支持
+ [x] 二进制支持
+ [ ] 混淆支持

1. 将 cocoapods 更新至最新版本.
2. 在 Podfile 中添加 `pod 'BDWebImage'`
3. 建议使用准确的版本进行依赖，如 `pod 'BDWebImage', '0.2.2'`
4. HEIC，Monitor，SDAdapter，HTSAdapter，YYAdapter 默认不会集成，需要手动添加 subspec
3. 执行 `pod install` 或 `pod update`
4. 在需要的地方 `#import <BDWebImage/BDWebImage.h>`


Swift支持：

+ [ ] 原生支持
+ [ ] 需要使用Modular Header
+ [x] 需要使用Briding Header

Extension支持：

+ 使用版本：1.0.2-rc.2
+ Podfile配置：

```
target 'TodayExtension' do
    project 'my-project.xcodeproj'
    pod 'BDWebImage', '1.0.2-rc.2', :subspecs => [
        'AppExtension',
        'Decoder',
        'Download/URLSession',
    ]
#   pod 'BDALog', '0.1.12'
end
```

### BDWebImageURLFilter
BDWebImageManager 支持设置URLFilter

```objc
- (NSString *)identifierWithURL:(NSURL *)url;
```
实现此方法后 manager 内部调度会根据具体的URL-key 计算策略来唯一标识一个图片请求，例如

* 多 CDN域名映射为同一个图片，内部缓存和下载策略去重
* 图片后缀兼容，例如多处访问同一个图片但是使用不同格式 webp 图片下载之后可以不用下载 jpg 版本
* 多图片size 支持

###  BDWebImageRequest

每个图片请求会对应一个BDWebImageRequest，manager会内部调度决定取缓存策略或者下载策略，多个相同 request 内部只会下载一次

request 支持设置超时时间，重试备选 URL，重试次数，缓存策略等
#### 备选 URL机制

```objc
@property (nonatomic, strong) NSArray<NSURL *> *alternativeURLs;
```
设置alternativeURLs后如果默认URL请求失败会判断失败原因，如果由于设备网络原因则终止请求返回错误，如果遇到 超时、NDS解析失败、链接主机失败等原因会触发备选 URL逻辑，默认按照数组顺序重试，直到所有 URL失败才会返回错误。

#### 重试次数
```objc
@property (nonatomic, assign)NSInteger maxRetryCount;
```
如果最大重试数大于1，下载失败后会判断失败原因，如果由于设备网络原因则终止请求返回错误，如果遇到 超时、NDS解析失败、链接主机失败等原因会触发重试逻辑，超过重试次数后返回结果
如果备选 URL和重试逻辑重试存在，先触发备选 URL逻辑

在下载时指定 BDImageNoRetry  Option，下载失败都不会重试。

### 从 URL 加载图片

```objc
//从网络加载图片
//完整图片加载
//如果命中内存图片默认不会提供data，需要提供data请加上BDImageRequestNeedCachePath
- (BDWebImageRequest *)bd_setImageWithURL:(NSURL *)imageURL
                          alternativeURLs:(NSArray *)alternativeURLs
                              placeholder:(UIImage *)placeholder
                                  options:(BDImageRequestOptions)options
                          timeoutInterval:(CFTimeInterval)timeoutInterval
                                cacheName:(NSString *)cacheName
                              transformer:(BDBaseTransformer *)transformer
                                 progress:(BDImageRequestProgressBlock)progress
                               completion:(BDImageRequestCompletedBlock)completion;

//提供一组便捷方法，可以根据需求选择
NSURL *url = [NSURL URLWithString:@"https://i.v2ex.co/8yc8q36x.jpeg"];
[imageView bd_setImageWithURL:url];
```

### 加载动图

支持动图播放需要显示控件支持。
只需要把 `UIImageView` 替换为 `BDImageView` 即可。
BDImageView 背后由BDAnimatedImagePlayer支持动图调度，支持边下边播，边解边播，自动处理内存缓存策略，默认播放策略按照图片meta信息，可以设置循环次数，缓存策略
详细信息参照注释说明

```objc
UIImageView *imageView = [BDImageView new];
[imageView bd_setImageWithURL:[NSURL URLWithString:@"https://ws4.sinaimg.cn/large/006tKfTcly1fnl2s3o2p4g30fk08rnpf.gif"]];
```

### 渐进式图片加载

```objc
//边下载边显示
NSURL *url = [NSURL URLWithString:@"https://i.v2ex.co/8yc8q36x.jpeg"];
[imageView bd_setImageWithURL:url options:BDImageProgressiveDownload];
//对于动图，类似 chrome 浏览器播放动图的效果，会一边下载一边播放已经下载好的帧
[imageView bd_setImageWithURL:[NSURL URLWithString:@"https://ws4.sinaimg.cn/large/006tKfTcly1fnl3r44e79g30am062qv8.gif"] options:BDImageProgressiveDownload];
```

### 加载，处理图片

```objc
//BDWebImage 已经预置了一些常用 transformer，比如加圆角
BDRoundCornerTransformer *transformer = [BDRoundCornerTransformer defaultTransformer];
    [imageView bd_setImageWithURL:url placeholder:nil options:BDImageProgressiveDownload transformer:transformer progress:^(BDWebImageRequest *request, NSInteger receivedSize, NSInteger expectedSize) {
        progress = (float)receivedSize / expectedSize;
    } completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (from == BDWebImageResultFromDiskCache) {
            NSLog(@"load from disk cache");
        }
    }];
```

### 图片缓存

由于业务场景不同，强烈建议业务方设置自己的缓存策略，否则使用默认缓存策略可能性能表现可能有较大差异

```objc
    BDImageCacheConfig *cacheConfig = [[BDImageCacheConfig alloc] init];
    cacheConfig.clearMemoryOnMemoryWarning = YES; //收到 memory warning 的时候清空内存缓存
    cacheConfig.clearMemoryWhenEnteringBackground = YES; //应用进入后台清空内存缓存
    cacheConfig.memoryCountLimit = NSUIntegerMax;    //内存缓存数量限制，默认无限制
    cacheConfig.memorySizeLimit = NSUIntegerMax;     //内存缓存大小限制，默认无限制。单位 byte
    cacheConfig.memoryAgeLimit = 12 * 60 * 60;       //内存缓存存活时长 12 小时
    cacheConfig.trimDiskWhenEnteringBackground = YES;//应用进入后台时清理超限或过期的磁盘缓存
    cacheConfig.diskCountLimit = NSUIntegerMax;    //磁盘缓存对象个数
    cacheConfig.diskSizeLimit = 256 * 1024 * 1024; //磁盘缓存大小限制 256M
    cacheConfig.diskAgeLimit = 7 * 24 * 60 * 60;   //磁盘缓存最大时长 7 天
    [BDImageCache sharedImageCache].config = cacheConfig;
```

```objc
BDImageCache *cache = [BDImageCache sharedImageCache];
cache.totalDiskSize;//同步获取磁盘缓存的所有数据的字节数
[cache trimDiskCache];//同步根据设置的最大磁盘大小，对象数量和过期时间，清除过期的缓存
[cache clearMemory];//清除内存缓存中的所有数据
[cache clearDiskWithBlock:^{
    NSLog(@"disk cleared");//回调在 YYDiskCache内部的子线程上
}];
```

### 图片预加载

```objc
NSURL *url = [NSURL URLWithString:@"http://p3.pstatp.com/large/w960/4775000261266dd5c0eb.heic"];
[[BDWebImageManager sharedManager] prefetchImageWithURL:url category:nil options:BDImageRequestDefaultOptions];
```

## Monitor

添加 Monitor subspec 即可对图片下载，解码等过程进行监控，内部使用了 TTMonitor 来进行数据上报。

同时，你也需要在Sladar平台上配置上报的采样率：

    "allow_service_name": {"image_monitor_v2": 1xxxx}

你可以通过 `request.recorder.requestImageSize`设置要要请求的图片像素大小。

## 适配层

为方便各业务线以最小的成本接入，BDWebImage 在过渡期提供了适配层。目前各业务线用到了的接口，均已完成适配。适配层同样通过 UIImageView 和 UIButton 的分类方式实现，使用方便。使用时按需要引入 subspec 即可。

```
pod 'BDWebImage/YYAdapter'

pod 'BDWebImage/SDAdapter'

pod 'BDWebImage/HTSAdapter'
```

### YYAdapter For Aweme

需要修改业务代码，将原接口中 yy 替换成 yya 即可，比如 `yy_setImageWithURL` 修改成了 `yya_setImageWithURL`

### SDAdapter For wenda and tt_ios_app

需要修改业务代码。
1. 将原接口中 sd 替换成 sda ，比如 `sd_setImageWithURL` 修改成了 `sda_setImageWithURL`
2. 原来直接使用 `SDWebImagePrefetcher`，`SDWebImageDownloader`，`SDImageCache`等的地方修改为使用 `[SDWebImageAdapter sharedAdapter]`, 通过适配层来调用，适配层通过下发控制字段实现灰度放量。


#### tt_ios_app 中使用了 SDWebImage 的 pod

1. TTUGCFoundation
2. EffectPlatformSDK
3. TTAvatar
4. TTImagePicker
5. TTLive
6. TTPhotoScrollVC
7. TTPushAuthorizationManager
8. TTShareService
9. TTUIWidget
10. TTVerifyKit
11. TTWebViewBundle
12. TTWenda


### HTSAdapter For HotSoon

HotSoon 使用插件的方式接入 BDWebImage，无需修改业务代码，在 HTSWebImage 中条件分支可以实现灰度放量。

### 图片库切换过程中可能产生的问题

1.  旧缓存清理，在 BD 中实现一个清除 sd/yy 磁盘缓存的功能供业务方在适当时机调用。

## 进阶特性介绍

1. 指向同一个文件的不同 url 共用一份缓存，典型场景如多个CDN域名。业务方可以继承 `BDWebImageURLFilter` 类, 重写方法 `- (NSString *)identifierWithURL:(NSURL *)url;` 实现自己的 hash 让同一张图片的不同 url hash 结果相等。
2. 只需要下载图片到本地磁盘然后告诉调用方磁盘路径，典型场景如头条文章详情页 webview。调用时增加 BDImageRequestIgnoreImage 和 BDImageRequestNeedCachePath 选项，可以跳过解码过程，节省性能。
3. 控制图片缓存大小，通过自定义 BDImageCacheConfig 中各项，平衡内存占用和 CPU 占用。
4. 发送请求时，可以使用 `BDImageNotDecoderForDisplay` 指定是否 Force Redraw 解码；也可以使用`isDecoderForDisplay`来统一开关。默认是会 Force Redraw ，这可以提高FPS，但对于大图会出现内存峰值，参考[文档](https://docs.bytedance.net/doc/kZWZOhofAtlbTHoG8IGZJd)。在1.0.2.alpha.2版本加入。
5. 下载图片时，可以使用 `BDImageShouldScaleDown` 来自动缩小，如果图片生成的CGImage大于60M，则会把图片的长宽等比例缩小，缩小到CGImage为60M。生效的前提是没有关闭 Force Redraw。如果发生缩小操作，下载回调中的 `image` 为缩小后图片，而 `data` 为原始数据。可以通过`UIImage`的`bd_isDidScaleDown`属性判断是否发生了缩小。在1.0.2-alpha.2版本加入。


## 库维护文档

1. [设计文档](https://code.byted.org/iOS_Library/BDWebImage/blob/master/docs/design.md)
2. [性能表现](https://code.byted.org/iOS_Library/BDWebImage/blob/master/docs/benchmark.md)
3. [HEIC解码器性能对比](https://bytedance.feishu.cn/space/sheet/shtcnzzyTh6FQ2tQh82r1q#95b271)

## 组件交流反馈群

* 有问题欢迎提 issues
* 欢迎[点击加入Lark交流群](lark://client/chatchatId=6639610038878994701)

## 贡献代码
欢迎提 Merge Request。

* 提MR之前请跑通项目中的 unit test
* 请遵守[开发标准](https://docs.bytedance.net/doc/XsvKsghTnhFmypxNYsqJ2c)。

## 版本更新日志

* 新的更新请参见[文档](https://docs.bytedance.net/doc/doccnVcPkPM9BLn6FmmoJM)


## 作者
linyong.ly@bytedance.com

zhangtianfu@bytedance.com

liushibin@bytedance.com

wusizhen.arch@bytedance.com

yangjing.rico@bytedance.com

fengyadong@bytedance.com

lizhuoli@bytedance.com

## 许可证

只限公司内部使用
