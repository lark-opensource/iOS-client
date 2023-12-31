//
//  BDWebImageDownloader.h
//  AFgzipRequestSerializer
//
//  Created by 刘诗彬 on 2017/12/6.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDDownloadImpl) {
    BDDownloadImplURLSession = 0,
    BDDownloadImplChromium,
    BDDownloadImplURLConnection,
};

typedef NS_ENUM(NSInteger, BDDownloadIsThumbnailExist)
{
    BDDownloadThumbnailNotDetermined= 0,
    BDDownloadThumbnailExist,
    BDDownloadThumbnailNotExist,
};

#pragma mark - task

/**
 下载任务的时间信息
 */
@protocol BDWebImageDownloadTaskTimeInfo <NSObject>

@property (nonatomic, assign, readonly) double repackStartTime;
@property (nonatomic, assign, readonly) double repackEndTime;
@property (nonatomic, assign, readonly) double startTime;
@property (nonatomic, assign, readonly) double finishTime;

@end

/**
 HEIC渐进式下载任务信息
 */
@protocol BDWebImageDownloadTaskHEICProgressiveInfo <NSObject>


@property (nonatomic, assign) BOOL needHeicProgressDownloadForThumbnail; ///< 用来标记流式下载时是否需要渐进解码，当找到缩略图or确定无缩略图时将标志位置为No
@property (nonatomic, assign) BDDownloadIsThumbnailExist isThumbnailExist; ///< 用来判断下载后的imageData是否有缩略图，如果有需要剥离后存入磁盘
@property (nonatomic, assign) NSInteger minDataLengthForThumbnail; ///< 最小能解出缩略图的数据长度
@property (nonatomic, assign) BOOL isHeicThumbDecodeFired; ///是否已经触发HEIC渐进加载缩略图解码

@end

/**
 任务的基本信息
 */
@protocol BDWebImageDownloadTaskBaseInfo <NSObject>

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, copy) NSString *identifier; ///< 和BDWebImageRequest 的 requestKey 为对应关系
@property (nonatomic, assign) CFTimeInterval timeoutInterval;   ///< 服务器响应的超时时间，针对 BDImageProgressiveDownload 生效
@property (nonatomic, assign) CFTimeInterval timeoutIntervalForResource;    ///< 资源下载的超时时间，只针对 BDImageProgressiveDownload 生效

@property (nonatomic, assign) CGRect smartCropRect;

@property (nonatomic, assign, readonly) long long receivedSize;
@property (nonatomic, assign, readonly) long long expectedSize;
@property (nonatomic, assign, readonly) long long realSize;         ///< 当开启了 heic 渐进式式 repack 能力的时候需要用于存储真实下载的 data size

@end

/**
 下载任务的 response info
 */
@protocol BDWebImageDownloadTaskResponseInfo <NSObject>

@property (nonatomic, strong, readonly) NSNumber *DNSDuration;  ///< DNS耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *connetDuration;   ///< 建立连接耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *sslDuration;  ///< SSL建连耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *sendDuration; ///< 发送耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *waitDuration; ///< 等待耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *receiveDuration;  ///< 接收耗时 单位ms
@property (nonatomic, strong, readonly) NSNumber *totalDuration;    ///< 下载总耗时 单位ms

@property (nonatomic, assign, readonly) NSInteger cacheControlTime;

@property (nonatomic, strong, readonly) NSNumber *isSocketReused;
@property (nonatomic, strong, readonly) NSNumber *isFromProxy;

@property (nonatomic, copy, readonly) NSString *mimeType;   ///< 图片类型
@property (nonatomic, assign, readonly) NSInteger statusCode;   ///<  http请求状态码
@property (nonatomic, copy, readonly) NSString *nwSessionTrace; ///< 图片系统在response header中增加的追踪信息，目前包含回复时间戳和处理总延迟
@property (nonatomic, copy, readonly) NSDictionary *responseHeaders;    ///< 返回response header的x-response-cache字段信息
@property (nonatomic, strong, readonly) NSNumber *isHitCDNCache;  ///< 是否命中CDN缓存
@property (nonatomic, copy, readonly) NSString *imageXDemotion;  ///< 处理是否降级
@property (nonatomic, copy, readonly) NSString *imageXWantedFormat;      ///< 请求的图片格式
@property (nonatomic, copy, readonly) NSString *imageXRealGotFormat;      ///< 真实下发的图片格式
@property (nonatomic, strong, readonly) NSNumber *imageXConsistent;    ///< 比较请求格式与解码的图片格式，1为相同，0为不同，-1为未知

@optional
@property (nonatomic, strong, readonly) NSNumber *isCached;
@property (nonatomic, copy, readonly) NSString *remoteIP;
@property (nonatomic, strong, readonly) NSNumber *remotePort;
@property (nonatomic, copy, readonly) NSString *requestLog;

@end

@protocol BDWebImageDownloadTask <NSObject, BDWebImageDownloadTaskBaseInfo, BDWebImageDownloadTaskResponseInfo, BDWebImageDownloadTaskTimeInfo, BDWebImageDownloadTaskHEICProgressiveInfo>

- (void)cancel;
@end

#pragma mark - downloader
/**
 BDWebImageDownloaderInfo
 @note BDWebImageDownloader 中使用的数据
 */
@protocol BDWebImageDownloaderInfo <NSObject>

@property (nonatomic, assign) NSInteger maxConcurrentTaskCount; ///< 最大同时下载任务
@property (nonatomic, assign) CFTimeInterval timeoutInterval;    ///< 服务器响应时间间隔
@property (nonatomic, assign) CFTimeInterval timeoutIntervalForResource; ///< 资源下载时间间隔
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *defaultHeaders;   ///< http request default headers
@property (nonatomic, assign) BOOL enableLog;
@property (nonatomic, assign) BOOL checkMimeType;
@property (nonatomic, assign) BOOL checkDataLength;
@property (nonatomic, assign) BOOL isCocurrentCallback; ///< default : NO

@end

/**
  任务管理
 */
@protocol BDWebImageDownloaderManagement <NSObject>

/**
 返回 identifier 对应的 task
 */
- (id<BDWebImageDownloadTask>)taskWithIdentifier:(NSString *)identifier;

/**
 取消 identifier 对应的 task
 */
- (void)cancelTaskWithIdentifier:(NSString *)identifier;

@end


@protocol BDWebImageDownloader;
/**
 下载器代理，实现此协议则可作为BDWebImageManager的下载模块
 */
@protocol BDWebImageDownloaderDelegate

/**
 任务下载失败
 @param downloader 当前的下载器
 @param task 当前下载的任务
 @param error 错误码
 */
- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
   failedWithError:(NSError *)error;

/**
 任务下载成功
 @param downloader 当前的下载器
 @param task 当前下载的任务
 @param data 下载的数据
 @param savePath 数据保存的位置
 */
- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
  finishedWithData:(NSData *)data
          savePath:(NSString *)savePath;

@optional
- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
      receivedSize:(NSInteger)receivedSize
      expectedSize:(NSInteger)expectedSize;

- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
    didReceiveData:(NSData *)data
          finished:(BOOL)finished;

@end

@class BDDownloadTaskConfig;
/**
 下载任务的协议，里面包含了下载的接口
 */
@protocol BDWebImageDownloaderDownloading <NSObject>

/**
 请求url并返回对应task，如果已有相同identifier的现在任务存在则返回已有task
 
 @param url 下载的URL
 @param identifier 任务对应的标志符，这里对应的就是URL.absoluteString
 @param immediately 是否忽略队列立即开始请求，否则走队列逻辑
 @return 返回对应task
 */
- (id<BDWebImageDownloadTask>)downloadWithURL:(NSURL *)url
                                   identifier:(NSString *)identifier
                             startImmediately:(BOOL)immediately;

/**
 请求url并返回对应task，如果已有相同identifier的现在任务存在则返回已有task

 @param url 下载的URL
 @param identifier 任务对应的标志符，这里对应的就是URL.absoluteString
 @param priority 下载优先级
 @param timeoutInterval 服务器响应的时间间隔
 @param immediately 是否忽略队列立即开始请求，否则走队列逻辑
 @param progressDownload 是否需要进行渐进式下载
 @param verifyData 是否需要对下载的数据进行验证，通常情况下对于加密数据不会进行验证
 @return 返回对应task
 */
- (id<BDWebImageDownloadTask>)downloadWithURL:(NSURL *)url
                                   identifier:(NSString *)identifier
                                     priority:(NSOperationQueuePriority)priority
                              timeoutInterval:(CFTimeInterval)timeoutInterval
                             startImmediately:(BOOL)immediately
                             progressDownload:(BOOL)progressDownload
                                   verifyData:(BOOL)verifyData;

/**
 请求url并返回对应task，如果已有相同identifier的现在任务存在则返回已有task

 @param url 下载的URL
 @param identifier 任务对应的标志符，这里对应的就是URL.absoluteString
 @param priority 下载优先级
 @param timeoutInterval 服务器响应的时间间隔
 @param immediately 是否忽略队列立即开始请求，否则走队列逻辑
 @param progressDownload 是否需要进行渐进式下载
 @param progressDownloadForThumbnail 是否进行缩略图的渐进式下载，这个目前只针对 HEIC 静图，而且需要传入的 URL 包含 HEIC 静图的缩略图信息
 @param verifyData 是否需要对下载的数据进行验证，通常情况下对于加密数据不会进行验证
 @return 返回对应task
 */
- (id<BDWebImageDownloadTask>)downloadWithURL:(NSURL *)url
                                   identifier:(NSString *)identifier
                                     priority:(NSOperationQueuePriority)priority
                              timeoutInterval:(CFTimeInterval)timeoutInterval
                             startImmediately:(BOOL)immediately
                             progressDownload:(BOOL)progressDownload
             heicProgressDownloadForThumbnail:(BOOL)progressDownloadForThumbnail
                                   verifyData:(BOOL)verifyData;

/**
 请求url并返回对应task，如果已有相同identifier的现在任务存在则返回已有task

 @param url 下载的URL
 @param identifier 任务对应的标志符，这里对应的就是URL.absoluteString
 @param config 任务的相关配置
 @return 返回对应task
 */
- (id<BDWebImageDownloadTask>)downloadWithURL:(NSURL *)url
                                   identifier:(NSString *)identifier
                                       config:(BDDownloadTaskConfig *)config;

@end

/**
 BDWebImageDownloader
 */
@protocol BDWebImageDownloader <BDWebImageDownloaderInfo, BDWebImageDownloaderManagement, BDWebImageDownloaderDownloading>

@property (nonatomic, weak) id<BDWebImageDownloaderDelegate> delegate;

@end
