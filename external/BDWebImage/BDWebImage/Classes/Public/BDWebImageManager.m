//
//  BDWebImageManager.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDWebImageManager.h"
#import "BDWebImageManager+Private.h"
#import "BDWebImageError.h"
#import <pthread.h>
#import "UIImage+BDWebImage.h"
#import "BDWebImageRequest+Monitor.h"
#import "BDWebImageRequest+Private.h"
#import "BDImagePerformanceRecoder.h"
#import "BDWebImageMacro.h"
#import "BDBaseTransformer.h"
#import "BDWebImageRequest+Progress.h"
#import "BDWebImageCompat.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import "BDWebImageUtil.h"
#import "BDWebImageRequest+TTMonitor.h"
#import "BDImageCacheMonitor.h"
#import "BDImageLargeSizeMonitor.h"
#import "BDImageExceptionHandler.h"
#import "UIImage+BDWebImage.h"
#if __has_include(<TTNetworkManager/TTNetworkManager.h>)
#import <TTNetworkManager/TTNetworkManager.h>
#endif
#import "BDDownloadTask.h"
#import "BDImageDecoderFactory.h"
#import "BDDownloadTaskConfig.h"
#import "BDImageMetaInfo.h"

NSString * const kBDWebImageStartRequestImage       = @"kBDWebImageStartRequestImage";
NSString * const kBDWebImageDownLoadImageFinish     = @"kBDWebImageDownLoadImageFinish";

@interface BDWebImageManager ()<BDWebImageDownloaderDelegate>
{
    BDImageCache *_imageCache;
    NSMutableDictionary *_caches;
    
    NSMutableDictionary < NSString *, NSMutableArray<BDWebImageRequest * > *>*_requests;
    pthread_mutex_t _request_lock;
    pthread_mutex_t _cache_lock;
    pthread_mutex_t _manager_lock;
    NSMutableDictionary < NSString *, id<BDWebImageDownloader> > *_downloadContainer;
    dispatch_queue_t _progressTaskQueue;
    
    BDDownloadImpl _defaultDownloadImpl;
    BDBaseImpl _defaultBaseImpl;
}

@property (nonatomic, strong)BDImageCacheMonitor *cacheMonitor;

@end

@implementation BDWebImageManager
+ (instancetype)sharedManager
{
    static BDWebImageManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithCategory:nil];
    });
    return sharedManager;
}

- (instancetype)initWithCategory:(nullable NSString *)category
{
    if (self = [super init]) {
        if (isEmptyString(category)) {
            _imageCache = [BDImageCache sharedImageCache];
        } else {
            _imageCache = [[BDImageCache alloc] initWithName:[NSString stringWithFormat:@"com.bd.imagecache.%@",category]];
        }
        pthread_mutex_init(&_request_lock, NULL);
        pthread_mutex_init(&_cache_lock, NULL);
        pthread_mutex_init(&_manager_lock, NULL);
        _requests = [NSMutableDictionary dictionary];
        _maxConcurrentTaskCount = 10;
        _downloadContainer = [NSMutableDictionary dictionaryWithCapacity:2];
        _progressTaskQueue = dispatch_queue_create("com.bd.image.progress.decode", DISPATCH_QUEUE_SERIAL);
        _cacheMonitor = [BDImageCacheMonitor new];
        _isDecoderForDisplay = YES;
        _enableLog = YES;
        _enableMultiThreadHeicDecoder = NO;
        _enableCacheToMemory = YES;
        _isSystemHeicDecoderFirst = YES;
        _isCustomSequenceHeicsDecoderFirst = YES;
        _checkMimeType = YES;
        _checkDataLength = YES;
        _isPrefetchLowPriority = YES;
        _isPrefetchIgnoreImage = NO;
        _isNoticeLoadImage = NO;
        _enableAllImageDownsample = NO;
        _isCDNdowngrade = YES;
        _enableRepackHeicData = NO;
        _enableRemoveRedundantThumbDecode = NO;
        _defaultDownloadImpl = BDDownloadImplChromium;
        _adaptiveDecodePolicy = [NSString string];
#if __has_include(<BDWebImage/BDWebImage.h>)
        // internal下设置的默认值
        _defaultBaseImpl = BDBaseImplInternal;
#endif
#if __has_include(<BDWebImageToB/BDWebImageToB.h>)
        // tob下设置的默认值
        _defaultBaseImpl = BDBaseImplToB;
#ifdef RELEASE
        _enableLog = NO;
#endif
#endif
    }
    return self;
}

- (void)setIsCacheMonitorEnable:(BOOL)isCacheMonitorEnable
{
    _isCacheMonitorEnable = isCacheMonitorEnable;
    [_cacheMonitor setMonitorEnable:isCacheMonitorEnable];
}

- (void)setCacheMonitorInterval:(NSInteger)cacheMonitorInterval
{
    _cacheMonitorInterval = cacheMonitorInterval;
    [_cacheMonitor setTrackInterval:cacheMonitorInterval];
}

- (void)registCache:(BDImageCache *)cache forKey:(NSString *)key
{
    if (!cache || !key) {
        return;
    }
    pthread_mutex_lock(&_cache_lock);
    if (!_caches) {
        _caches = [NSMutableDictionary dictionary];
    }
    [_caches setObject:cache forKey:key];
    pthread_mutex_unlock(&_cache_lock);
}

- (BDImageCache *)cacheForKey:(NSString *)key
{
    if (!key) {
        return nil;
    }
    pthread_mutex_lock(&_cache_lock);
    BDImageCache *cache = [_caches objectForKey:key];
    pthread_mutex_unlock(&_cache_lock);
    return cache;
}

- (void)enumCacheForRequest:(BDWebImageRequest *)request block:(void (^)(BDImageCache *cache, BOOL *stop))block
{
    if (!block) {
        return;
    }
    BOOL stop = NO;
    if (self.insulatedCache && request.cacheName) {
        block([self cacheForKey:request.cacheName], &stop);
    } else {
        block(self.imageCache, &stop);
        if (!stop) {
            pthread_mutex_lock(&_cache_lock);
            NSArray *caches = _caches.allValues;
            pthread_mutex_unlock(&_cache_lock);
            for (BDImageCache *cache in caches) {
                block(cache,&stop);
                if (stop) {
                    break;
                }
            }
        }
    }
}

// 该函数返回初始化后的baseManager
- (id<BDBase>) BDBaseManagerFromOption
{
    Class clazz = nil;
    if (_defaultBaseImpl == BDBaseImplToB) {
        clazz = NSClassFromString(@"BDBaseToB");
    } else {
        clazz = NSClassFromString(@"BDBaseInternal");
    }
    
    if(!clazz) {
        return nil;
    }
    
    if (!_baseManager) {
        _baseManager = [[clazz alloc] init];
        if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"create BDBaseTypeManager: %@", NSStringFromClass(clazz));
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] create BDBaseTypeManager: %@", NSStringFromClass(clazz));
#endif
        }
    }
    return _baseManager;
}

- (BDBaseImpl)baseImpl{
    return _defaultBaseImpl;
}

- (void)startUpWithConfig:(BDWebImageStartUpConfig *)config{
    [[self BDBaseManagerFromOption] startUpWithConfig:config];
}

- (id<BDWebImageDownloader>)downloadManagerFromOption:(BDImageRequestOptions)option
{
    Class clazz = nil;
#if BDWEBIMAGE_APP_EXTENSIONS == 1
    clazz = NSClassFromString(@"BDDownloadURLSessionManager");
#else
#if __has_include(<TTNetworkManager/TTNetworkManager.h>)
    if ([TTNetworkManager getLibraryImpl] == TTNetworkManagerImplTypeAFNetworking) {
        _defaultDownloadImpl = BDDownloadImplURLSession;
    }
#endif
    if (_defaultDownloadImpl == BDDownloadImplChromium) {
        clazz = NSClassFromString(@"BDDownloadManager");
    } else {
        clazz = NSClassFromString(@"BDDownloadURLSessionManager");
    }
#endif
    if (!clazz) {
        //这里为保护case，因为如果在Extension Target中使用BDWebImage的话，可能不会引入TTNetwork ，而在使用BDDownloadManager时，内部逻辑会最终使用TTNetWork来请求
        clazz = NSClassFromString(@"BDDownloadURLSessionManager");
        if(!clazz){
            return nil;
        }
    }
    pthread_mutex_lock(&_manager_lock);
    if (!_downloadContainer[NSStringFromClass(clazz)]) {
        _downloadManager = [[clazz alloc] init];
        _downloadManager.delegate = self;
        _downloadManager.timeoutInterval = self.timeoutInterval;
        _downloadManager.timeoutIntervalForResource = self.timeoutIntervalForResource;
        _downloadContainer[NSStringFromClass(clazz)] = _downloadManager;
        if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"create downloadManager: %@", NSStringFromClass(clazz));
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] create downloadManager: %@", NSStringFromClass(clazz));
#endif
        }
    }else {
        _downloadManager = _downloadContainer[NSStringFromClass(clazz)];
    }
    _downloadManager.defaultHeaders = self.downloadManagerDefaultHeaders;
    _downloadManager.maxConcurrentTaskCount = self.maxConcurrentTaskCount;
    _downloadManager.enableLog = self.enableLog;
    _downloadManager.checkMimeType = self.checkMimeType;
    _downloadManager.checkDataLength = self.checkDataLength;
    _downloadManager.isCocurrentCallback = self.isCocurrentCallback;
    pthread_mutex_unlock(&_manager_lock);
    return _downloadManager;
}

- (void)setDownloadImpl:(BDDownloadImpl)downloadImpl
{
    _defaultDownloadImpl = downloadImpl;
}

- (BDDownloadImpl)downloadImpl
{
    return _defaultDownloadImpl;
}

- (void)setDownloaderWithClassName:(NSString *)className
{
    if (isEmptyString(className)) return;
    Class clazz = NSClassFromString(className);
    if (clazz) {
        _downloadManager = [[clazz alloc] init];
    }
    _downloadManager.delegate = self;
    _downloadManager.defaultHeaders = self.downloadManagerDefaultHeaders;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_request_lock);
    pthread_mutex_destroy(&_cache_lock);
    pthread_mutex_destroy(&_manager_lock);
}

- (instancetype)init
{
    return [self initWithCategory:nil];
}

- (NSString *)requestKeyWithURL:(nullable NSURL *)url
{
    // 防止业务传入的 URLs 中包含非nil的空值
    if ((NSNull *)url == [NSNull null]) {
        return nil;
    }
    
    if (self.urlFilter) {
        return [[self urlFilter] identifierWithURL:url];
    }
    return url.absoluteString;
}

- (NSString *)requestKeyWithSmartCropURL:(NSURL *)url {
    NSString *sourceUrl = url.absoluteString;
    if (self.urlFilter) {
        sourceUrl = [[self urlFilter] identifierWithURL:url];
    }
    BDImageRequestKey *key = [[BDImageRequestKey alloc] initWithURL:sourceUrl];
    key.smartCrop = YES;
    return [key targetkey];
}

- (NSArray *)requestsWithURL:(NSURL *)url
{
    pthread_mutex_lock(&_request_lock);
    NSArray *request = [[_requests objectForKey:[self requestKeyWithURL:url]] copy];
    pthread_mutex_unlock(&_request_lock);
    return request;
}

- (NSArray *)requestsWithCategory:(NSString *)category
{
    NSMutableArray *requests = [NSMutableArray array];
    pthread_mutex_lock(&_request_lock);
    for (NSArray *array in _requests.allValues) {
        for (BDWebImageRequest *request in array) {
            if ([request.category isEqualToString:category]) {
                [requests addObject:request];
            }
        }
    }
    pthread_mutex_unlock(&_request_lock);
    return requests;
}

- (NSArray<BDWebImageRequest *> *)prefetchImagesWithURLs:(NSArray<NSURL *> *)urls
                                                category:(nullable NSString *)category
                                                 options:(BDImageRequestOptions)options{
    return [self prefetchImagesWithURLs:urls cacheName:nil category:category options:options];
}

- (NSArray<BDWebImageRequest *> *)prefetchImagesWithURLs:(NSArray<NSURL *> *)urls
                                               cacheName:(nullable NSString *)cacheName
                                                category:(nullable NSString *)category
                                                 options:(BDImageRequestOptions)options
{
    NSMutableArray *requests = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        BDWebImageRequest *request = [self prefetchImageWithURL:url
                                                      cacheName:cacheName
                                                       category:category
                                                        options:options];
        if (request) {
            [requests addObject:request];
        }
    }
    return [requests copy];
}

- (BDWebImageRequest *)prefetchImageWithURL:(NSURL *)url
                                   category:(NSString *)category
                                    options:(BDImageRequestOptions)options
{
    return [self prefetchImageWithURL:url cacheName:nil category:category options:options];
}

- (BDWebImageRequest *)prefetchImageWithURL:(NSURL *)url
                                  cacheName:(nullable NSString *)cacheName
                                   category:(nullable NSString *)category
                                    options:(BDImageRequestOptions)options
{
    BDWebImageRequestConfig *config = [BDWebImageRequestConfig new];
    config.cacheName = cacheName;
    return [self prefetchImageWithURL:url category:category options:options config:config blocks:nil];
}

- (BDWebImageRequest *)prefetchImageWithURL:(NSURL *)url
                                   category:(nullable NSString *)category
                                    options:(BDImageRequestOptions)options
                                     config:(BDWebImageRequestConfig *)config {
    return [self prefetchImageWithURL:url category:category options:options config:config blocks:nil];
}

- (BDWebImageRequest *)prefetchImageWithURL:(NSURL *)url
                                   category:(nullable NSString *)category
                                    options:(BDImageRequestOptions)options
                                     config:(BDWebImageRequestConfig *)config
                                     blocks:(nullable BDWebImageRequestBlocks *)blocks;
{
    if (_enableLog) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"overAllStart|prefetch|url:%@", url);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] overAllStart|prefetch|url:%@", url);
#endif
    }

    if (self.urlFactory) {
        config = [self.urlFactory setupRequestConfig:config URL:url];
        options = [self.urlFactory setupRequestOptions:options URL:url];
    }

    BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:url];
    if (self.isPrefetchLowPriority) {
        options |= BDImageRequestLowPriority;
    }
    if (self.isPrefetchIgnoreImage) {
        options |= BDImageRequestIgnoreImage;
        options |= BDImageRequestNotCacheToMemery;
    }
    BDImageRequestDecryptBlock decryptBlock = blocks.decryptBlock;
    BDImageRequestProgressBlock progress = blocks.progressBlock;
    BDImageRequestCompletedBlock complete = blocks.completedBlock;
    
    request.isPrefetchRequest = YES;
    request.minNotifiProgressInterval = 1;
    request.option = options;
    request.category = category;
    request.userInfo = config.userInfo;
    request.sceneTag = config.sceneTag;
    request.cacheName = config.cacheName;
    request.randomSamplingPointCount = config.randomSamplingPointCount;
    request.requestHeaders = config.requestHeaders;
    request.decryptBlock = decryptBlock;
    request.progressBlock = progress;
    request.completedBlock = complete;
    [self requestImage:request];
    return request;
}

- (NSArray<BDWebImageRequest *> *)allPrefetchs
{
    NSMutableArray *requests = [NSMutableArray array];
    pthread_mutex_lock(&_request_lock);
    for (NSArray *array in _requests.allValues) {
        for (BDWebImageRequest *request in array) {
            if (request.isPrefetchRequest) {
                [requests addObject:request];
            }
        }
    }
    pthread_mutex_unlock(&_request_lock);
    return requests;
}

- (void)cancelAllPrefetchs
{
    [[self allPrefetchs] makeObjectsPerformSelector:@selector(cancel)];
}

- (void)cancelAll
{
    NSArray *allRequests;
    pthread_mutex_lock(&_request_lock);
    allRequests = _requests.allValues;
    [_requests removeAllObjects];
    pthread_mutex_unlock(&_request_lock);
    for (NSArray *array in allRequests) {
        [array makeObjectsPerformSelector:@selector(cancel)];
    }
}


- (BDWebImageRequest *)requestImage:(NSURL *)url
                            options:(BDImageRequestOptions)options
                           complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url
              alternativeURLs:nil
                      options:options
                    cacheName:nil
                     progress:NULL
                     complete:complete];
}

- (BDWebImageRequest *)requestImage:(NSURL *)url
                            options:(BDImageRequestOptions)options
                               size:(CGSize)size
                           complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url alternativeURLs:nil options:options size:size timeoutInterval:0 cacheName:nil transformer:nil decryptBlock:NULL progress:NULL complete:complete];
}

- (BDWebImageRequest *)requestImage:(NSURL *)url
                           progress:(BDImageRequestProgressBlock)progress
                           complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url
              alternativeURLs:nil
                      options:BDImageRequestDefaultOptions
                    cacheName:nil
                     progress:progress
                     complete:complete];
}

- (BDWebImageRequest *)requestImage:(NSURL *)url
                    alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                            options:(BDImageRequestOptions)options
                          cacheName:(NSString *)cacheName
                           progress:(BDImageRequestProgressBlock)progress
                           complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url
              alternativeURLs:alternativeURLs
                      options:options
                    cacheName:cacheName
                  transformer:nil
                     progress:progress
                     complete:complete];
}

- (BDWebImageRequest *)requestImage:(NSURL *)url
                    alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                            options:(BDImageRequestOptions)options
                          cacheName:(NSString *)cacheName
                        transformer:(BDBaseTransformer *)transformer
                           progress:(BDImageRequestProgressBlock)progress
                           complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url
              alternativeURLs:alternativeURLs
                      options:options
              timeoutInterval:0
                    cacheName:cacheName
                  transformer:transformer
                     progress:progress
                     complete:complete];
}

- (nullable BDWebImageRequest *)requestImage:(nullable NSURL *)url
                             alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                                     options:(BDImageRequestOptions)options
                             timeoutInterval:(CFTimeInterval)timeoutInterval
                                   cacheName:(NSString *)cacheName
                                 transformer:(BDBaseTransformer *)transformer
                                    progress:(BDImageRequestProgressBlock)progress
                                    complete:(BDImageRequestCompletedBlock)complete
{
    return [self requestImage:url alternativeURLs:alternativeURLs options:options size:CGSizeZero timeoutInterval:timeoutInterval cacheName:cacheName transformer:transformer decryptBlock:NULL progress:progress complete:complete];
    
}

- (nullable BDWebImageRequest *)requestImage:(nullable NSURL *)url
                             alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                                     options:(BDImageRequestOptions)options
                                        size:(CGSize)size
                             timeoutInterval:(CFTimeInterval)timeoutInterval
                                   cacheName:(NSString *)cacheName
                                 transformer:(BDBaseTransformer *)transformer
                                decryptBlock:(BDImageRequestDecryptBlock)decryptBlock
                                    progress:(BDImageRequestProgressBlock)progress
                                    complete:(BDImageRequestCompletedBlock)complete {
    BDWebImageRequestConfig *config = [BDWebImageRequestConfig new];
    config.size = size;
    config.cacheName = cacheName;
    config.timeoutInterval = timeoutInterval;
    config.transformer = transformer;
    
    BDWebImageRequestBlocks *blocks = [BDWebImageRequestBlocks new];
    blocks.decryptBlock = decryptBlock;
    blocks.progressBlock = progress;
    blocks.completedBlock = complete;
    
    return [self requestImage:url alternativeURLs:alternativeURLs options:options config:config blocks:blocks];
}

- (BDWebImageRequest *)requestImage:(NSURL *)url
                    alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                            options:(BDImageRequestOptions)options
                             config:(BDWebImageRequestConfig *)config
                             blocks:(BDWebImageRequestBlocks *)blocks
{
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    if (self.urlFactory) {
        config = [self.urlFactory setupRequestConfig:config URL:url];
        options = [self.urlFactory setupRequestOptions:options URL:url];
        blocks = [self.urlFactory setupRequestBlocks:blocks URL:url];
    }
    
    CGSize size = config.size;
    CFTimeInterval timeoutInterval = config.timeoutInterval;
    NSString *cacheName = config.cacheName;
    BDBaseTransformer *transformer = config.transformer;
    
    BDImageRequestDecryptBlock decryptBlock = blocks.decryptBlock;
    BDImageRequestProgressBlock progress = blocks.progressBlock;
    BDImageRequestCompletedBlock complete = blocks.completedBlock;
    
    if (![url isKindOfClass:[NSURL class]]) {
        if (complete) {
            complete(nil,
                     nil,
                     nil,
                     [NSError errorWithDomain:BDWebImageErrorDomain
                                         code:BDWebImageBadImageURL
                                     userInfo:@{NSLocalizedDescriptionKey:@"URL format error"}],
                     BDWebImageResultFromNone);
        }
        return nil;
    }
    
    if (_enableLog) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"overAllStart|url:%@", url.absoluteString);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] overAllStart|url:%@", url.absoluteString);
#endif
    }

    if (decryptBlock) {
        options |= BDImageRequestNotVerifyData;
    }

    BDWebImageRequest *request = [[BDWebImageRequest alloc] initWithURL:url];
    request.alternativeURLs = alternativeURLs;
    request.option = options;
    if ((options & BDImageNotDownsample) == 0) {
        request.downsampleSize = size;
    }
    request.cacheName = cacheName;
    [request setupKeyAndTransformer:transformer];
    request.decryptBlock = decryptBlock;
    request.progressBlock = progress;
    request.completedBlock = complete;
    request.timeoutInterval = timeoutInterval;
    request.userInfo = config.userInfo;
    request.sceneTag = config.sceneTag;
    request.randomSamplingPointCount = config.randomSamplingPointCount;
    request.requestHeaders = config.requestHeaders;
    [self requestImage:request];
    
    return request;
}

- (nullable BDWebImageRequest *)requestImage:(NSURL *)url
                             alternativeURLs:(NSArray<NSURL *> *)alternativeURLs
                                     options:(BDImageRequestOptions)options
                             timeoutInterval:(CFTimeInterval)timeoutInterval
                                   cacheName:(NSString *)cacheName
                                 transformer:(BDBaseTransformer *)transformer
                                decryptBlock:(BDImageRequestDecryptBlock)decryptBlock
                                    progress:(BDImageRequestProgressBlock)progress
                                    complete:(BDImageRequestCompletedBlock)complete;
{
    return [self requestImage:url alternativeURLs:alternativeURLs options:options size:CGSizeZero timeoutInterval:timeoutInterval cacheName:cacheName transformer:transformer decryptBlock:decryptBlock progress:progress complete:complete];
}

- (void)_cancelRequest:(BDWebImageRequest *)request
{
    pthread_mutex_lock(&_request_lock);
    NSMutableArray *requests = [_requests objectForKey:request.requestKey];
    [requests removeObject:request];
    BOOL cancelDownload = YES;
    for (BDWebImageRequest *request in requests) {
        if (request.isPrefetchRequest == NO) {
            cancelDownload = NO;
        }
    }
    if (cancelDownload) {
        [[self downloadManagerFromOption:request.option] cancelTaskWithIdentifier:request.requestKey];
    }
    if (requests.count <= 0) {//该 url 对应的所有 request 都没有了清空字典中这一项
        [_requests removeObjectForKey:request.requestKey];
    }
    pthread_mutex_unlock(&_request_lock);
}

- (void)requestImage:(BDWebImageRequest *)request
{
    //block abnormal request
    if (isEmptyString(request.currentRequestURL.absoluteString)) {
        request.error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageBadImageURL userInfo:nil];
        [request finishWithImage:nil data:nil savePath:nil url:nil from:BDWebImageResultFromNone];
        return;
    }
    
    if (!self.isDecoderForDisplay) {
        request.option |= BDImageNotDecoderForDisplay;
    }
    
    if (!self.enableCacheToMemory) {
        request.option |= BDImageRequestNotCacheToMemery;
    }
    
    BDImageRequestTimestamp(request,overallStartTime);
    request.recorder.options = request.option;
    request.recorder.timeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    if (!request.requestKey) {
        request.requestKey = [self requestKeyWithURL:request.currentRequestURL];
    }
    if (isEmptyString(request.requestKey)) {
        request.error = [NSError errorWithDomain:BDWebImageErrorDomain code:BDWebImageBadImageURL userInfo:nil];
        [request finishWithImage:nil data:nil savePath:nil url:nil from:BDWebImageResultFromNone];
        return;
    }
    NSString *bizTag = @"";
    if (self.bizTagURLFilterBlock) {
        bizTag = self.bizTagURLFilterBlock(request.currentRequestURL);
        if (![bizTag isKindOfClass:[NSString class]] || bizTag.length < 1) {
            bizTag = @"";
        }
    }
    NSString *sceneTag = @"";
    if (self.sceneTagURLFilterBlock) {
        sceneTag = self.sceneTagURLFilterBlock(request.currentRequestURL);
        if (![sceneTag isKindOfClass:[NSString class]] || sceneTag.length < 1) {
            sceneTag = @"";
        }
    }
   
    // 通知发起图片加载请求
    [self bd_noticeStartReuqestImage:request];
    if ((request.option & BDImageRequestIgnoreCache) == BDImageRequestIgnoreCache) {
        [self downloadImageWithRequest:request];
    } else {
        BDImageRequestTimestamp(request, cacheSeekStartTime);
        if (request.isPrefetchRequest) {
            __weak typeof(self)weakSelf = self;
            [self cacheContainsImageForRequest:request cacheNoneBlock:^(BDImageCacheType cacheType) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                [strongSelf.cacheMonitor onRecordType:cacheType bizTag:bizTag];
                if (cacheType != BDImageCacheTypeNone) {
                    [self bd_noticeDownLoadImageFinish:request image:nil from:BDWebImageResultFromDiskCache];
                    [request finishWithImage:nil
                                        data:nil
                                    savePath:nil
                                         url:nil
                                        from:(cacheType == BDImageCacheTypeMemory) ? BDWebImageResultFromMemoryCache : BDWebImageResultFromDiskCache];
                    return;
                }
                if (strongSelf.enableLog) {
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"no need cache|url:%@", request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] no need cache|url:%@", request.currentRequestURL.absoluteString);
#endif
                }
                
                [strongSelf downloadImageWithRequest:request];
            }];
        } else {
            
            if (_enableLog) {
#if __has_include("BDBaseInternal.h")
                BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cache|start|url:%@", request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                NSLog(@"[BDWebImageToB] cache|start|url:%@", request.currentRequestURL.absoluteString);
#endif
            }
            __weak typeof(self)weakSelf = self;
            [self queryCacheForRequest:request callback:^(UIImage *image, NSString *cachePath, BDImageCacheType cacheType) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                request.recorder.cacheType = cacheType;
                BDImageRequestTimestamp(request, cacheSeekEndTime)
                [strongSelf.cacheMonitor onRecordType:cacheType bizTag:bizTag];
                if (cacheType == BDImageCacheTypeNone) {
                    if (strongSelf.enableLog) {
#if __has_include("BDBaseInternal.h")
                        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cache|NotFound|url:%@", request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                        NSLog(@"[BDWebImageToB] cache|NotFound|url:%@", request.currentRequestURL.absoluteString);
#endif
                    }
                    // 没有找到大图缓存，尝试找缩略图内存缓存
                    if ((request.option & BDImageHeicProgressDownloadForThumbnail) && !(request.option & BDImageRequestIgnoreMemoryCache)){
                        BDImageRequestTimestamp(request, thumbCacheSeekStartTime);
                        UIImage *image = [self _thumbImageFromMemoryQuery:request];
                        BDImageRequestTimestamp(request, thumbCacheSeekEndTime)
                        // 找到缩略图缓存，设置，继续原大图下载逻辑
                        if (image) {
                            [request thumbnailFinished:image from:BDWebImageResultFromMemoryCache];
                        }
                    }
                    [strongSelf downloadImageWithRequest:request];
                } else {
                    if (strongSelf.enableLog) {
#if __has_include("BDBaseInternal.h")
                        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cache|cache found|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                        NSLog(@"[BDWebImageToB] cache|cache found|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#endif
                    }
                    if (!image.bd_requestKey) {
                        image.bd_requestKey = request.originalKey;
                    }
                    if (!image.bd_webURL) {
                        image.bd_webURL = request.currentRequestURL;
                    }
                    if ((request.option & BDImageRequestPreloadAllFrames) == BDImageRequestPreloadAllFrames && [image isKindOfClass:[BDImage class]]) {
                        [((BDImage *)image) preloadAllFrames];
                    }
                    NSData *data = nil;
                    if (cachePath.length > 0) {
                        NSError *error;
                        data = [NSData dataWithContentsOfFile:cachePath options:NSDataReadingMappedIfSafe error:&error];
                        if (error) {
#if __has_include("BDBaseInternal.h")
                            BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"map data file failed, %@", error.localizedDescription);
#elif __has_include("BDBaseToB.h")
                            NSLog(@"[BDWebImageToB] map data file failed, %@", error.localizedDescription);
#endif
                        } else {
                            // 当option设置为 BDImageRequestIgnoreImage | BDImageRequestNeedCachePath 时，会从磁盘中获取 data，此时的data为密文
                            NSError *decodeError = nil;
                            if (request.decryptBlock) {
                                data = request.decryptBlock(data, &decodeError);
                            }
                        }
                    }
                    BDWebImageResultFrom from = (cacheType == BDImageCacheTypeMemory) ? BDWebImageResultFromMemoryCache : BDWebImageResultFromDiskCache;
                    [self bd_noticeDownLoadImageFinish:request image:image from:from];
                    [request finishWithImage:image
                                        data:data
                                    savePath:cachePath
                                         url:nil
                                        from:from];
                }
            }];
        }
    }
    // 设置上报block
    [request ttMonitorRecordPerformance];
}

- (void)cacheContainsImageForRequest:(BDWebImageRequest *)request
                      cacheNoneBlock:(void (^)(BDImageCacheType cacheType))cacheContainsBlock
{
    __block BDImageCacheType cacheType = BDImageCacheTypeNone;
    NSString *cacheKey = request.originalKey.targetkey;
    /// 先同步查询内存缓存
    [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
        cacheType = [cache containsImageForKey:cacheKey type:BDImageCacheTypeMemory];
        if (cacheType!=BDImageCacheTypeNone) {
            *stop = YES;
        }
    }];
    if (cacheType == BDImageCacheTypeNone) {
        NSString *sourceKey = request.originalKey.sourceKey;
        /// 异步查询磁盘缓存，还是没有开始下载
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
                cacheType = [cache containsImageForKey:sourceKey type:BDImageCacheTypeDisk];
                if (cacheType!=BDImageCacheTypeNone) {
                    *stop = YES;
                }
            }];
            cacheContainsBlock(cacheType);

            if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
                BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cache|cache contains image|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                NSLog(@"[BDWebImageToB] cache|cache contains image|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#endif
            }
        });
    } else {
        cacheContainsBlock(cacheType);

        if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cache|cache contains image|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] cache|cache contains image|cacheType: %tu|url:%@", cacheType, request.currentRequestURL.absoluteString);
#endif
        }
    }
}

/// 同步查内存缓存（缩略图）
- (UIImage *)_thumbImageFromMemoryQuery:(BDWebImageRequest *)request
{
    __block UIImage *image = nil;
    
    NSString *sourceThumbKey = request.originalKey.sourceThumbKey;
    [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
        image = [cache imageFromMemoryCacheForKey:sourceThumbKey];
        if (image) {
            *stop = YES;
        }
    }];
    return image;
}

/// 同步查内存缓存
- (UIImage *)_imageFromMemoryQuery:(BDWebImageRequest *)request
{
    __block UIImage *image = nil;
    __block BDImageCache *tempCache = nil;
    
    NSString *targetkey = request.originalKey.targetkey;
    NSString *sourceKey = request.originalKey.sourceKey;
    [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
        image = [cache imageFromMemoryCacheForKey:targetkey];
        if (image) {
            tempCache = cache;
            *stop = YES;
        }
    }];

    if (image) {
        NSString *rectStr = [tempCache imageInfoForkey:sourceKey withInfoType:BDImageCacheSmartCropInfo];
        CGRect cropRect = CGRectFromString(rectStr);
        request.smartCropRect = cropRect;
    }
    return image;
}

///> 同步从磁盘取图片，注意：本方法应谨慎在主线程调用
- (UIImage *)_imageFromDiskQuery:(BDWebImageRequest *)request
{
    
#define CHECK_REQUEST_CANCEL         if (request.cancelled || !request) { return nil;}
    
    __block UIImage *image = nil;
    __block BDImageCache *matchCache = nil;
    
    NSString *sourceKey = request.originalKey.sourceKey;
    NSString *targetKey = request.originalKey.targetkey;
    [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
        BDImageCacheType type = BDImageCacheTypeDisk;
        image = [cache imageForKey:sourceKey withType:&type options:request.option size:request.downsampleSize decryptBlock:request.decryptBlock];
        if (image) {
            matchCache = cache;
            *stop = YES;
        }
        if (request.cancelled) {
            *stop = YES;
        }
    }];
    if (image) {
        if (request.transformer) {
            if ([request.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)]) {
                CHECK_REQUEST_CANCEL
                UIImage * realImage = [request.transformer transformImageBeforeStoreWithImage:image];
                if (realImage) {
                    image = realImage;
                }
            }
        }
        if ((request.option & BDImageRequestNotCacheToMemery) == 0) {
            [matchCache setImage:image
                       imageData:nil
                          forKey:targetKey
                        withType:BDImageCacheTypeMemory];//TODO,如果设置不存内存则跳过存内存
        }
        NSString *rectStr = [matchCache imageInfoForkey:sourceKey withInfoType:BDImageCacheSmartCropInfo];
        CGRect cropRect = CGRectFromString(rectStr);
        if (!CGRectEqualToRect(cropRect, CGRectZero)) {
            request.smartCropRect = cropRect;
        }
    }
    
#undef CHECK_REQUEST_CANCEL
    return image;
}
///> 同步查询 cachePath
- (NSString *)_queryCachePath:(BDWebImageRequest *)request
{
    __block NSString *cachePath = nil;
    NSString *cacheKey = request.originalKey.sourceKey;
    
    [self enumCacheForRequest:request block:^(BDImageCache *cache, BOOL *stop) {
        cachePath = [cache cachePathForKey:cacheKey];
        *stop = cachePath!=nil;
    }];
    return cachePath;
}

/**
 逻辑有点多，整理一下：
 1. 开启 BDImageRequestIgnoreImage 选项，不需要将 NSData 解码 UIImage
 2. 开启 BDImageRequestNeedCachePath 选项，需要返回 NSData 在磁盘中的路径
 3. 目前的业务场景中，1和2常搭配使用即 needPath && !needImage（头条详情页WebView)。但图片库支持分开控制。
 4. 如果存在 transform，将原图和 transform 之后的图片都存内存和磁盘
 5. 故存在五个 BOOL 变量（needImage，needPath，transformer，ignoreDisk，ignoreMem）互相组合
 6. 应该先同步查询内存缓存（异步查询内存缓存会导致 collectionView reloadData 闪烁的问题），再异步查询磁盘缓存
 */
- (void)queryCacheForRequest:(BDWebImageRequest *)request
                    callback:(void (^)(UIImage *image,NSString *cachePath, BDImageCacheType cacheType))callback
{
    BDImageRequestOptions options = request.option;
    BOOL needImage = (options & BDImageRequestIgnoreImage) == 0;
    BOOL needPath = (options & BDImageRequestNeedCachePath) != 0;

    BOOL shouldQueryMemory = ( (options & BDImageRequestIgnoreMemoryCache) == 0 );
    BOOL shouldQueryDisk   = ( (options & BDImageRequestIgnoreDiskCache) == 0 );
    
    if (needImage) {
        [self queryImageForRequest:request memory:shouldQueryMemory disk:shouldQueryDisk callback:^(UIImage *image, BDImageCacheType cacheType) {
            if (needPath) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *cachePath = [self _queryCachePath:request];
                    !callback ?: callback(image, cachePath, cachePath ? cacheType | BDImageCacheTypeDisk : cacheType);
                });
            } else {
                !callback ?: callback(image, nil, cacheType);
            }
        }];
    } else if (needPath) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *cachePath = [self _queryCachePath:request];
            !callback ?: callback(nil, cachePath, cachePath ? BDImageCacheTypeDisk : BDImageCacheTypeNone);
        });
    } else {
        !callback ?: callback(nil, nil, BDImageCacheTypeNone);
    }
}

-(void)queryImageForRequest:(BDWebImageRequest *)request
                     memory:(BOOL)shouldQueryMemory
                       disk:(BOOL)shouldQueryDisk
                   callback:(void (^)(UIImage *image, BDImageCacheType cacheType))callback
{
    UIImage *image = nil;
    if (shouldQueryMemory) {
        image = [self _imageFromMemoryQuery:request];
        if (image) {//使用内存缓存，且查询到 UIImage 对象
            !callback ?: callback(image, BDImageCacheTypeMemory);
            return;
        }
    }
    if (shouldQueryDisk) {
        void(^queryDiskBlock)(void) = ^{
            if (request.isCancelled || request.isFinished || !request) {// do not call the completion if cancelled
                return;
            }
            UIImage *diskImage = [self _imageFromDiskQuery:request];
            !callback ?: callback(diskImage, diskImage ? BDImageCacheTypeDisk : BDImageCacheTypeNone);
        };
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), queryDiskBlock);
        return;
    }
    !callback ?: callback(nil, BDImageCacheTypeNone);
}

- (void)downloadImageWithRequest:(BDWebImageRequest *)request
{
    if (request.cancelled) {
        return;
    }
    pthread_mutex_lock(&_request_lock);
    NSMutableArray *requests = [_requests objectForKey:request.requestKey];
    if (!requests) {
        requests = [NSMutableArray array];
        [_requests setObject:requests forKey:request.requestKey];
        request.recorder.enableReport = YES;
        [[BDImageExceptionHandler sharedHandler] registerRecord:request.recorder];
    }
    if (![requests containsObject:request]) {
        [requests addObject:request];
    }
    self.adaptiveDecodePolicy = self.enableAdaptiveDecode ?[[self BDBaseManagerFromOption] adaptiveDecodePolicy] : @"image/*";

    BDDownloadTaskConfig *config = [BDDownloadTaskConfig new];
    config.priority = [self transformQueuePriority:request.option];
    config.timeoutInterval = request.timeoutInterval;
    config.immediately = (request.option&BDImageRequestIgnoreQueue) > 0;
    config.progressDownload = (request.option & BDImageProgressiveDownload) || (request.option & BDImageAnimatedImageProgressiveDownload) || (request.option & BDImageStaticImageProgressiveDownload);
    config.progressDownloadForThumbnail = (request.option & BDImageHeicProgressDownloadForThumbnail) && !(request.option & BDImageRequestSmartCorp);
    config.verifyData = !(request.option & BDImageRequestNotVerifyData);
    config.requestHeaders = request.requestHeaders;

    [[self downloadManagerFromOption:request.option] downloadWithURL:request.currentRequestURL
                                                          identifier:request.requestKey
                                                            config:config];
    pthread_mutex_unlock(&_request_lock);
}

- (NSOperationQueuePriority)transformQueuePriority:(BDImageRequestOptions)option
{
    NSOperationQueuePriority priority = NSOperationQueuePriorityNormal;
    if (option & BDImageRequestLowPriority) {
        priority = NSOperationQueuePriorityLow;
    }
    if (option & BDImageRequestHighPriority) {
        priority = NSOperationQueuePriorityHigh;
    }
    return priority;
}

#pragma mark BDDownloadTaskDelegate
- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
   failedWithError:(NSError *)error
{
#if __has_include("BDBaseInternal.h")
    BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"download|fail|errorCode:%ld|errorDesc:%@|url:%@", error.code, error.localizedDescription, task.url.absoluteString);
#elif __has_include("BDBaseToB.h")
    NSLog(@"[BDWebImageToB] download|fail|errorCode:%ld|errorDesc:%@|url:%@", error.code, error.localizedDescription, task.url.absoluteString);
#endif
    
    pthread_mutex_lock(&_request_lock);
    NSArray *requests = [_requests objectForKey:task.identifier];
    [self _recordPerformanceValuesForRequests:requests withTask:task];
    [_requests removeObjectForKey:task.identifier];
    pthread_mutex_unlock(&_request_lock);
    for (BDWebImageRequest *request in requests) {
        [self bd_noticeDownLoadImageFinish:request image:nil from:BDWebImageResultFromNone];
        [request failedWithError:error];
    }
}

- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
  finishedWithData:(NSData *)data
          savePath:(NSString *)savePath
{
    NSString *taskIdentifier = task.identifier;
    NSMutableDictionary<NSString *, NSMutableArray *> *requestsMap = [NSMutableDictionary dictionary];
    pthread_mutex_lock(&_request_lock);
    NSArray *requests = [_requests objectForKey:taskIdentifier];
    [_requests removeObjectForKey:taskIdentifier];
    for (BDWebImageRequest *request in requests) {
        NSString *targetKey = request.originalKey.targetkey;
        NSMutableArray *targetRequests = [requestsMap objectForKey:targetKey];
        if (targetRequests == nil) {
            targetRequests = [NSMutableArray array];
        }
        [targetRequests addObject:request];
        [requestsMap setObject:targetRequests forKey:targetKey];
    }
    
    pthread_mutex_unlock(&_request_lock);
    if (!data) {
        data = [NSData dataWithContentsOfFile:savePath];
    }
    [requestsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
        [self decodeImageForReuqests:obj task:task finishedWithData:data];
    }];
}

- (void)decodeImageForReuqests:(NSArray *)requests
                          task:(id<BDWebImageDownloadTask>)task
              finishedWithData:(NSData *)data
{
    [self _recordPerformanceValuesForRequests:requests withTask:task];
    
    NSError *decodeError = nil;
    UIImage *image = nil;
    NSMutableSet<BDImageCache *> *caches = [NSMutableSet set];
    
    BDWebImageRequest *currentRequest = nil;
    
    BOOL needImage = NO;
    BOOL needPath = NO;
    BOOL decodeForDisplay = NO;
    BOOL shouldScaleDown = NO;
    
    BDImageCacheType cacheType = BDImageCacheTypeNone;
    CGSize targetSize = CGSizeZero;
    CGRect targetRect = CGRectZero;
    
    // init decode & cache info
    pthread_mutex_lock(&_cache_lock);
    for (BDWebImageRequest *request in requests) {
        if (request.cacheName) {
            BDImageCache *requestCache = [_caches objectForKey:request.cacheName];
            if (requestCache != nil) {
                [caches addObject:requestCache];
            }
        }

        if ([request.currentRequestURL.absoluteString isEqualToString:task.url.absoluteString]) {
            currentRequest = request;
        }
        
        needImage = needImage || (request.option & BDImageRequestIgnoreImage) == 0;
        needPath = needPath || (request.option & BDImageRequestNeedCachePath) != 0;
        decodeForDisplay = decodeForDisplay || (request.option & BDImageNotDecoderForDisplay) == 0;
        shouldScaleDown = shouldScaleDown || (request.option & BDImageScaleDownLargeImages) != 0;
        
        if ((request.option & BDImageRequestNotCacheToMemery) == 0) {
            cacheType |= BDImageCacheTypeMemory;
        }
        
        if ((request.option & BDImageRequestNotCacheToDisk) == 0) {
            cacheType |= BDImageCacheTypeDisk;
        }
        
        request.smartCropRect = task.smartCropRect;
    }
    pthread_mutex_unlock(&_cache_lock);
    
    if ((currentRequest.option & BDImageRequestSmartCorp) == BDImageRequestSmartCorp) {
        targetRect = task.smartCropRect;
    }
    targetSize = currentRequest.downsampleSize;
    
    NSData *encryptData = nil;
    if (currentRequest.decryptBlock) {
        currentRequest.isNeedDecrptyData = YES;
        encryptData = data;
        data = currentRequest.decryptBlock(encryptData, &decodeError);
    }
    
    // 大图监控
    if (self.shouldDecodeImageBlock && needImage){
        needImage = self.shouldDecodeImageBlock([[BDImageMetaInfo alloc] initWithRequest:currentRequest data:data]);
    }

    if (needPath) {
        cacheType |= BDImageCacheTypeDisk;
    }
    
    BOOL isIgnoreDowngrade = (currentRequest.option & BDImageRequestIgnoreCDNDowngrade) == BDImageRequestIgnoreCDNDowngrade || (!CGRectIsEmpty(task.smartCropRect)&&self.isSmartCropIgnoreDowngrade);
    if (self.isCDNdowngrade && task.cacheControlTime <= 1 * 60 * 60 && task.cacheControlTime != 0 && !isIgnoreDowngrade) {
        cacheType = cacheType & BDImageCacheTypeMemory ? BDImageCacheTypeMemory : BDImageCacheTypeNone;
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"CDN downgrade with url:%@",task.url);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] CDN downgrade with url:%@",task.url);
#endif
    }
    
    // decode
    if (!data) {
        if (!decodeError) {
            decodeError = [NSError errorWithDomain:BDWebImageErrorDomain
                                              code:BDWebImageBadImageData
                                          userInfo:@{NSLocalizedDescriptionKey:@"decode data is empty"}];
        }
    } else if(needImage) {
        static Class imageClass = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            imageClass = NSClassFromString(@"BDImage")?:[UIImage class];
        });
        
        [self _recordPerformanceValue:@(CACurrentMediaTime() * 1000) forKey:NSStringFromSelector(@selector(decodeStartTime)) forTask:task forRequests:requests];
        
        CGFloat scale = BDScaledFactorForKey(task.request.URL.absoluteString);
        image = [BDWebImageUtil decodeImageData:data
                                     imageClass:imageClass
                                          scale:scale
                               decodeForDisplay:decodeForDisplay
                                shouldScaleDown:shouldScaleDown
                                 downsampleSize:targetSize
                                       cropRect:targetRect
                                          error:&decodeError];
        (image).bd_requestKey = currentRequest.originalKey;
        (image).bd_webURL = currentRequest.currentRequestURL;
        [self _recordPerformanceValue:@(CACurrentMediaTime() * 1000) forKey:NSStringFromSelector(@selector(decodeEndTime)) forTask:task forRequests:requests];
        
        if (!image) {
            decodeError = decodeError ? decodeError : [NSError errorWithDomain:BDWebImageErrorDomain
                                                                          code:BDWebImageEmptyImage
                                                                      userInfo:@{NSLocalizedDescriptionKey:@"decode failed"}];
        } else {
            if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
                BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|decode success|codeType:%tu|url:%@", ((BDImage*)image).codeType, task.url.absoluteString);
#elif __has_include("BDBaseToB.h")
                NSLog(@"[BDWebImageToB] download|decode success|codeType:%tu|url:%@", ((BDImage*)image).codeType, task.url.absoluteString);
#endif
            }
        }
    }
    
    if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|success|url:%@", task.request.URL.absoluteString);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] download|success|url:%@", task.request.URL.absoluteString);
#endif
    }
    
    if ((currentRequest.option & BDImageRequestPreloadAllFrames) == BDImageRequestPreloadAllFrames && [image isKindOfClass:[BDImage class]]) {
        [((BDImage *)image) preloadAllFrames];
    }
    // transform
    UIImage *realImage = nil;
    if (image && [currentRequest.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)]) {
        realImage = [currentRequest.transformer transformImageBeforeStoreWithImage:image];//如果是动图直接返回了原图
        (realImage).bd_requestKey = currentRequest.originalKey;
        (realImage).bd_webURL = currentRequest.currentRequestURL;
        if (needImage && !realImage && !(decodeError)) {
            decodeError = [NSError errorWithDomain:BDWebImageErrorDomain
                                              code:BDWebImageEmptyImage
                                          userInfo:@{NSLocalizedDescriptionKey:@"transform image failed"}];
        }
        if (realImage) {
            image = realImage;
        }
    }
    
    // cache
    [self _recordPerformanceValue:@(CACurrentMediaTime() * 1000) forKey:NSStringFromSelector(@selector(cacheImageBeginTime)) forTask:task forRequests:requests];
    
    if (caches.count == 0) {
        [caches addObject:self.imageCache];
    }
    NSString *targetkey = currentRequest.originalKey.targetkey;
    NSString *sourceKey = currentRequest.originalKey.sourceKey;
    if (image || data) {
        [caches enumerateObjectsUsingBlock:^(BDImageCache * _Nonnull obj, BOOL * _Nonnull stop) {
            if (image && (cacheType & BDImageCacheTypeMemory)) {
                    [obj setImage:image
                        imageData:nil
                           forKey:targetkey
                         withType:BDImageCacheTypeMemory];
            }
            if (data && (cacheType & BDImageCacheTypeDisk)) {
                [obj setImage:nil
                    imageData:currentRequest.isNeedDecrptyData ? encryptData : data
                       forKey:sourceKey
                     withType:BDImageCacheTypeDisk];
                
                if (!CGRectEqualToRect(currentRequest.smartCropRect, CGRectZero)) {
                    [obj setImageInfo:NSStringFromCGRect(currentRequest.smartCropRect)
                               forKey:sourceKey
                         withInfoType:BDImageCacheSmartCropInfo];
                    
                    if ([image isKindOfClass:[BDImage class]]) {
                        [obj setImageInfo:NSStringFromCGSize(((BDImage *)image).originSize)
                                   forKey:sourceKey
                             withInfoType:BDImageCacheSizeInfo];
                    }
                }
            }
        }];
    }
    [self _recordPerformanceValue:@(CACurrentMediaTime() * 1000) forKey:NSStringFromSelector(@selector(cacheImageEndTime)) forTask:task forRequests:requests];
    
    // finish
    for (BDWebImageRequest *request in requests) {
        if (!(decodeError)) {
            [self bd_noticeDownLoadImageFinish:request image:image from:BDWebImageResultFromDownloading];
            [self bd_recordLargeImageInfo:image data:data task:task forRequest:request];
            [request finishWithImage:realImage ? realImage : image
                                data:data
                            savePath:needPath ? [[BDImageCache sharedImageCache] cachePathForKey:sourceKey] : nil
                                 url:task.request.URL
                                from:BDWebImageResultFromDownloading];
        } else {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"download|fail|errorCode:%ld|errorDesc:%@|url:%@", decodeError.code, decodeError.localizedDescription, task.url.absoluteString);
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] download|fail|errorCode:%ld|errorDesc:%@|url:%@", decodeError.code, decodeError.localizedDescription, task.url.absoluteString);
#endif
            [request failedWithError:decodeError];
        }
    }
}

- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
      receivedSize:(NSInteger)receivedSize
      expectedSize:(NSInteger)expectedSize
{
    pthread_mutex_lock(&_request_lock);
    NSArray *requests = [_requests objectForKey:task.identifier];
    for (BDWebImageRequest *request in requests) {
        [request _setReceivedSize:receivedSize andExpectedSize:expectedSize];
    }
    pthread_mutex_unlock(&_request_lock);
}

- (void)downloader:(id<BDWebImageDownloader>)downloader
              task:(id<BDWebImageDownloadTask>)task
    didReceiveData:(NSData *)data finished:(BOOL)finished
{
    NSString *key = task.identifier;
    pthread_mutex_lock(&_request_lock);
    NSArray *requests = [_requests objectForKey:key];
    for (BDWebImageRequest *request in requests) {
        //基于现有的模型，这里可能会有不对齐的风险，后续可以考虑优化
        if ([request.currentRequestURL.absoluteString isEqualToString:task.url.absoluteString]) {
            [self _receiveProgressData:data finished:finished taskQueue:_progressTaskQueue task:task request:request];
        }
    }
    pthread_mutex_unlock(&_request_lock);
}

- (BOOL)isRepackNeeded:(NSData *)data
{
    BDImageCodeType type = BDImageDetectType((__bridge CFDataRef)data);
    if (type != BDImageCodeTypeHeif && type != BDImageCodeTypeHeic) {
        return NO;
    }

    Class<BDThumbImageDecoder> decoderClaz = NSClassFromString(@"BDImageDecoderHeic");
    if ([decoderClaz respondsToSelector:@selector(parseThumbLocationForHeicData:minDataSize:)]) {
        NSInteger ret = [decoderClaz parseThumbLocationForHeicData:data minDataSize:nil];
        if (ret == BDImageHeicThumbLocationFounded) {
            return YES;
        }
    }
    return NO;
}

- (NSMutableData *)heicRepackData:(NSData *)data
{
    Class<BDThumbImageDecoder> decoderClaz = NSClassFromString(@"BDImageDecoderHeic");
    if ([decoderClaz respondsToSelector:@selector(heicRepackData:)]) {
        return [decoderClaz heicRepackData:data];
    }
    return nil;
}

#pragma mark - private Method

- (void)_receiveProgressData:(NSData *)currentReceiveData
                    finished:(BOOL)finished
                   taskQueue:(dispatch_queue_t)queue
                        task:(id<BDWebImageDownloadTask>)task
                     request:(BDWebImageRequest*)request
{
    if (task.needHeicProgressDownloadForThumbnail) {
        // 所能识别type的最长字节数为32，如果接收的数据 <32 有可能获取到的codeType不正确
        if (currentReceiveData.length < 32) {
            return;
        }
        BDImageCodeType codeType = BDImageDetectType((__bridge CFDataRef)currentReceiveData);
        if (codeType != BDImageCodeTypeHeif && codeType != BDImageCodeTypeHeic) {
            task.needHeicProgressDownloadForThumbnail = NO;
        } else {
            // 只能使用自研软解库
            Class<BDThumbImageDecoder> cls = NSClassFromString(@"BDImageDecoderHeic");
            if (cls && [cls respondsToSelector:@selector(isStaticHeicImage:)]) {
                if ([cls isStaticHeicImage:currentReceiveData]) {
                    [self _receiveProgressDataOfHeicImage:currentReceiveData finished:finished taskQueue:queue task:task request:request];
                    return;
                }
            } else {
                task.needHeicProgressDownloadForThumbnail = NO;
            }
        }
    }
    [request _receiveProgressData:currentReceiveData finished:finished taskQueue:queue task:task];
}

- (void)_receiveProgressDataOfHeicImage:(NSData *)currentReceiveData
                               finished:(BOOL)finished
                              taskQueue:(dispatch_queue_t)queue
                                   task:(id<BDWebImageDownloadTask>)task
                                request:(BDWebImageRequest*)request
{
    if (task.minDataLengthForThumbnail && currentReceiveData.length < task.minDataLengthForThumbnail) {
        return;
    }
    
    // 选择合适的解码库
    Class<BDThumbImageDecoder> decoderClaz = NSClassFromString(@"BDImageDecoderHeic");
    if (![decoderClaz respondsToSelector:@selector(supportDecodeThumbFromHeicData)] || ![decoderClaz supportDecodeThumbFromHeicData]) {
        task.needHeicProgressDownloadForThumbnail = NO;
        return;
    }
    if (!task.minDataLengthForThumbnail) {
        NSInteger minDataSize;
        NSInteger ret = [decoderClaz parseThumbLocationForHeicData:currentReceiveData minDataSize:&minDataSize];
        if (ret == BDImageHeicThumbLocationNotFound) {
            task.needHeicProgressDownloadForThumbnail = NO;
            task.isThumbnailExist = BDDownloadThumbnailNotExist;
            return;
        } else if (ret == BDImageHeicThumbLocationNotDetermined){
            task.isThumbnailExist = BDDownloadThumbnailNotDetermined;
            return;
        }
        if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"HeicProgressDecodeThumbnail:url:%@ Get Thumbnail Location", request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
            NSLog(@"[BDWebImageToB] HeicProgressDecodeThumbnail:url:%@ Get Thumbnail Location", request.currentRequestURL.absoluteString);
#endif
        }
        BDImageRequestTimestamp(request, thumbFindLocationEndTime);
        task.isThumbnailExist = BDDownloadThumbnailExist;
        task.minDataLengthForThumbnail = minDataSize;
        if (currentReceiveData.length < minDataSize) {
            return;
        }
    } else if (task.isHeicThumbDecodeFired) {
        return;
    }
    task.isHeicThumbDecodeFired = YES;
    BDImageRequestTimestamp(request, thumbDownloadEndTime);

    // 解码
    BOOL enableRemoveRedundant = self.enableRemoveRedundantThumbDecode;
    dispatch_async(queue, ^{
        if (!task.needHeicProgressDownloadForThumbnail) {
            return;
        }
        BDImageRequestTimestamp(request, thumbDecodeStartTime);
        id<BDThumbImageDecoder> decoder = [[(Class)decoderClaz alloc] initWithData:currentReceiveData];
        if (enableRemoveRedundant && task.receivedSize >= task.expectedSize) {
            return;
        }
        CGImageRef imageRef = [decoder decodeThumbImage];
        if (!imageRef) {
            return;
        }
        if (enableRemoveRedundant && task.receivedSize >= task.expectedSize) {
            CFRelease(imageRef);
            return;
        }
        task.needHeicProgressDownloadForThumbnail = NO;
        UIImage* thumbImage = [[UIImage alloc] initWithCGImage:imageRef];
        CFRelease(imageRef);
        if (!thumbImage) {
            return;
        }
        BDImageRequestTimestamp(request, thumbDecodeEndTime);
        // transformer
        UIImage *realThumbImage = nil;
        if ([request.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)] && request.transformer.isAppliedToThumbnail) {
            realThumbImage = [request.transformer transformImageBeforeStoreWithImage:thumbImage];
        }else {
            realThumbImage = thumbImage;
        }
        realThumbImage.bd_webURL = [request.currentRequestURL copy];
        realThumbImage.bd_isThumbnail = TRUE;
        // 加入内存缓存
        if (!(request.option & BDImageRequestIgnoreMemoryCache)) {
            BDImageCache* thumbCache = request.cacheName ? [self cacheForKey:request.cacheName] : self.imageCache;
            if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
                BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"HeicProgressDecodeThumbnail:url:%@ Set Thumbnail To Memory Cache", request.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                NSLog(@"[BDWebImageToB] HeicProgressDecodeThumbnail:url:%@ Set Thumbnail To Memory Cache", request.currentRequestURL.absoluteString);
#endif
            }
            [thumbCache setImage:realThumbImage imageData:nil forKey:request.originalKey.sourceThumbKey withType:BDImageCacheTypeMemory];
        }
        [request thumbnailFinished:realThumbImage from:BDWebImageResultFromDownloading];
    });
}

- (void)_callbackWithImage:(UIImage *)image data:(NSData *)data savePath:(NSString *)savePath url:(NSURL *)url forKey:(NSString *)key
{
    if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|success|url:%@", url.absoluteString);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] download|success|url:%@", url.absoluteString);
#endif
    }

    pthread_mutex_lock(&_request_lock);
    NSArray *requests = [_requests objectForKey:key];
    [_requests removeObjectForKey:key];
    pthread_mutex_unlock(&_request_lock);
    for (BDWebImageRequest *request in requests) {
        [request finishWithImage:image data:data savePath:savePath url:url from:BDWebImageResultFromDownloading];
    }
}

- (void)bd_noticeStartReuqestImage:(BDWebImageRequest *)request
{
    if (self.isNoticeLoadImage) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kBDWebImageStartRequestImage object:nil userInfo:@{@"requestImageObj": request.uuid}];
    }
}

- (void)bd_noticeDownLoadImageFinish:(BDWebImageRequest *)request
                               image:(UIImage *)image
                                from:(BDWebImageResultFrom)from
{
    if (_isNoticeLoadImage) {
        NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
        [imageInfo setObject:@(from) forKey:@"from"];
        [imageInfo setObject:request.uuid forKey:@"requestImageObj"];
        [imageInfo setObject:request.currentRequestURL forKey:@"imageUrl"];
        [imageInfo setObject:request.recorder forKey:@"requestRecord"];
        if (request.userInfo) {
            [imageInfo setObject:request.userInfo forKey:@"userInfo"];
        }
        if (image) {
            [imageInfo setObject:@([image bd_imageCost]) forKey:@"imageMemorySize"];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kBDWebImageDownLoadImageFinish object:nil userInfo:imageInfo];
    }
}

- (void)bd_recordLargeImageInfo:(UIImage *)image data:(NSData *)data task:(id<BDWebImageDownloadTask>)task forRequest:(BDWebImageRequest *)request
{
    request.largeImageMonitor.loadSuccess = YES;
    request.largeImageMonitor.fileSize = data.length > 0 ? data.length : task.expectedSize;
    request.largeImageMonitor.imageURL = request.currentRequestURL;
    request.largeImageMonitor.requestImage = image;
    if (self.largeImageMonitorCallBack) {
        self.largeImageMonitorCallBack(request.largeImageMonitor);
    }
}

- (void)_recordPerformanceValue:(NSNumber *)value
                         forKey:(NSString *)key
                        forTask:(id<BDWebImageDownloadTask>)task
                    forRequests:(NSArray<BDWebImageRequest *> *)requests
{
    pthread_mutex_lock(&_request_lock);
    [requests setValue:value forKeyPath:[NSString stringWithFormat:@"recorder.%@",key]];
    pthread_mutex_unlock(&_request_lock);
}

- (void)_recordPerformanceValuesForRequests:(NSArray *)requests
                                   withTask:(id<BDWebImageDownloadTask>)task
{
    for (BDWebImageRequest *request in requests) {
        if ([task respondsToSelector:@selector(expectedSize)]) {
            request.recorder.totalBytes = task.realSize ?: task.expectedSize;
        }
        
        if ([task respondsToSelector:@selector(receivedSize)]) {
            request.recorder.receivedBytes = task.receivedSize;
        }
        if ([task respondsToSelector:@selector(repackStartTime)]) {
            request.recorder.repackStartTime = task.repackStartTime;
        }
        if ([task respondsToSelector:@selector(repackEndTime)]) {
            request.recorder.repackEndTime = task.repackEndTime;
        }
        if ([task respondsToSelector:@selector(startTime)]) {
            request.recorder.downloadStartTime = task.startTime;
        }
        if ([task respondsToSelector:@selector(finishTime)]) {
            request.recorder.downloadEndTime = task.finishTime;
        }
        if ([task respondsToSelector:@selector(DNSDuration)]) {
            request.recorder.DNSDuration = task.DNSDuration;
        }
        if ([task respondsToSelector:@selector(connetDuration)]) {
            request.recorder.connetDuration = task.connetDuration;
        }
        if ([task respondsToSelector:@selector(sslDuration)]) {
            request.recorder.sslDuration = task.sslDuration;
        }
        if ([task respondsToSelector:@selector(sendDuration)]) {
            request.recorder.sendDuration = task.sendDuration;
        }
        if ([task respondsToSelector:@selector(waitDuration)]) {
            request.recorder.waitDuration = task.waitDuration;
        }
        if ([task respondsToSelector:@selector(receiveDuration)]) {
            request.recorder.receiveDuration = task.receiveDuration;
        }
        
        if ([task respondsToSelector:@selector(isSocketReused)]) {
            request.recorder.isSocketReused = task.isSocketReused;
        }
        
        if ([task respondsToSelector:@selector(isCached)]) {
            request.recorder.isCached = task.isCached;
        }
        
        if ([task respondsToSelector:@selector(isFromProxy)]) {
            request.recorder.isFromProxy = task.isFromProxy;
        }
        
        if ([task respondsToSelector:@selector(remoteIP)]) {
            request.recorder.remoteIP = task.remoteIP;
        }
        
        if ([task respondsToSelector:@selector(remotePort)]) {
            request.recorder.remotePort = task.remotePort;
        }
        
        if ([task respondsToSelector:@selector(requestLog)]) {
            request.recorder.requestLog = task.requestLog;
        }
       
        if ([task respondsToSelector:@selector(mimeType)]) {
            request.recorder.mimeType = task.mimeType;
        }
        
        if ([task respondsToSelector:@selector(statusCode)]) {
            request.recorder.statusCode = task.statusCode;
        }
        
        if ([task respondsToSelector:@selector(nwSessionTrace)]) {
            request.recorder.nwSessionTrace = task.nwSessionTrace;
        }
        
        if ([task respondsToSelector:@selector(responseHeaders)]){
            request.recorder.responseHeaders = task.responseHeaders;
        }
        
        if ([task respondsToSelector:@selector(isHitCDNCache)]){
            request.recorder.isHitCDNCache = task.isHitCDNCache;
        }
        
        if ([task respondsToSelector:@selector(imageXDemotion)]){
            request.recorder.imageXDemotion = task.imageXDemotion;
        }
        
        if ([task respondsToSelector:@selector(imageXConsistent)]){
            request.recorder.imageXConsistent = task.imageXConsistent;
        }
        
        if ([task respondsToSelector:@selector(imageXWantedFormat)]){
            request.recorder.imageXWantedFormat = task.imageXWantedFormat;
        }
        
        if ([task respondsToSelector:@selector(imageXRealGotFormat)]){
            request.recorder.imageXRealGotFormat = task.imageXRealGotFormat;
        }
        
        if ([task respondsToSelector:@selector(minDataLengthForThumbnail)]){
            request.recorder.thumbBytes = task.minDataLengthForThumbnail;
        }
    }
}
@end
