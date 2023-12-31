//
//  BDWebImageRequest.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//
static NSString *const kTTNetworkErrorDomain = @"kTTNetworkErrorDomain";

NSString *const BDWebImageSetAnimationKey = @"SetImageAnimation";

#import "BDWebImageRequest.h"
#import <pthread.h>
#import "BDWebImageManager+Private.h"
#import "BDWebImageRequest+Monitor.h"
#import "BDWebImageRequest+Private.h"
#import "BDImagePerformanceRecoder.h"
#import "BDImageLargeSizeMonitor.h"
#import "BDImageSensibleMonitor.h"
#import "BDWebImageError.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import "BDImageDecoderFactory.h"
#import "BDBaseTransformer.h"
#import "UIImage+BDWebImage.h"
#import "BDWebImageCompat.h"
#import "BDImageDecoder.h"
#if __has_include("BDWebImage.h")
#import "BDWebImage.h"
#else
#import "BDWebImageToB.h"
#endif
#import "BDWebImageUtil.h"


@interface BDWebImageRequest()
{
    NSString *_requestKey;
    double _lastNotifiedProgress;
    CFTimeInterval _beginTime;
    CFTimeInterval _endTime;
    
    NSUInteger _currentIndex;
    
    NSUInteger _retriedCount;
    
    BOOL _finished;
    
    //for progress handle
//    double _tempLastNotifiedProgress;
    BOOL _needUpdateProgress;
}

@property (nonatomic, strong) BDImageRequestKey *originalKey;

@property (nonatomic, strong) BDImageDecoderConfig *config;

@end

@implementation BDWebImageRequest

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithURL:url alternativeURLs:url? @[url] : nil];
}

- (instancetype)initWithURL:(NSURL *)url alternativeURLs:(NSArray *)alternativeURLs
{
//    NSParameterAssert(url);
#if DEBUG
    if (!url) NSLog(@"WARNING, URL IS NIL!");
#endif
    self = [super init];
    if (self) {
        if (url && alternativeURLs.count && ![alternativeURLs containsObject:url]) {
            NSMutableArray *newURLArray = [NSMutableArray array];
            [newURLArray addObject:url];
            [newURLArray addObjectsFromArray:alternativeURLs];
            _alternativeURLs = [newURLArray copy];
        } else {
            _alternativeURLs = alternativeURLs;
        }
        //只传入备选数组的话区取第一个
        if (!url && _alternativeURLs.count) {
            url = alternativeURLs.firstObject;
        }
        [self setCurrentRequestURL:url];
        _minNotifiProgressInterval = 0.05;
        _beginTime = CACurrentMediaTime();
        NSString *urlStr = @"";
        if ([url isKindOfClass:[NSURL class]]) {
            urlStr = url.absoluteString;
        } else {
            urlStr = [url isKindOfClass:[NSString class]] ? (NSString *)url : @"";
        }
        _uuid = [[NSUUID UUID] UUIDString];
        _originalKey = [[BDImageRequestKey alloc] initWithURL:urlStr];
        _recorder = [[BDImagePerformanceRecoder alloc] initWithRequest:self];
        // 大图监控初始化
        _largeImageMonitor = [BDImageLargeSizeMonitor new];
        _largeImageMonitor.monitorEnable = [BDWebImageRequest isMonitorLargeImage];
        if (BDWebImageRequest.largeImageFileSizeLimit > 0) {
            _largeImageMonitor.fileSizeLimit = BDWebImageRequest.largeImageFileSizeLimit;
        }
        if (BDWebImageRequest.largeImageMemoryLimit > 0) {
            _largeImageMonitor.memoryLimit = BDWebImageRequest.largeImageMemoryLimit;
        }
        _maxRetryCount = 3;//最多重试3次，默认
        _requestHeaders = [NSDictionary dictionary];
    }
    return self;
}

- (void)setAlternativeURLs:(NSArray<NSURL *> *)alternativeURLs
{
    if (![alternativeURLs containsObject:self.currentRequestURL]) {
        alternativeURLs = [alternativeURLs arrayByAddingObject:self.currentRequestURL];
    }
    _alternativeURLs = alternativeURLs;
}

- (BOOL)isFinished
{
    return _finished;
}

- (BOOL)isFailed
{
    return _finished && (!self.image);
}

- (NSUInteger)currentIndex
{
    return _currentIndex;
}

- (void)cancel
{
    _retriedCount = 0;
    [self setCurrentRequestURL:[self.alternativeURLs firstObject]];
    _currentIndex = 0;
    self.completedBlock = nil;
    self.progressBlock = nil;
    
    if (_finished) {
        return;
    }
//    _cancelRequest 有副作用（side-effect)，如果不 strongify 一下 self，self 会被释放
    if (ENABLE_LOG) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"cancelled before finished, url: %@", self.currentRequestURL);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] cancelled before finished, url: %@", self.currentRequestURL);
#endif
    }
    __strong typeof(self) sSelf = self;//延迟释放 self，arc 下 self 是 unsafe_unretain 会导致野指针 crash
    [[BDWebImageManager sharedManager] _cancelRequest:sSelf];//此处参数也可以用self，sSelf只是为了消除警告；
    self.image = nil;
    self.data = nil;
    self.error = [NSError errorWithDomain:BDWebImageErrorDomain
                                     code:BDWebImageCancelled
                                 userInfo:@{NSLocalizedDescriptionKey:@"image request cancelled"}];
    
    [self willChangeValueForKey:@"cancelled"];
    _cancelled = YES;
    [self didChangeValueForKey:@"cancelled"];
}

- (BOOL)canRetryWithError:(NSError *)error
{
    if ((self.option & BDImageNoRetry) != 0) {
        return NO;
    }
    if ([BDWebImageRequest needRetryByHttps:error.code]) {
        return YES;
    }
    if (error.code == NSURLErrorNetworkConnectionLost ||
        error.code == NSURLErrorNotConnectedToInternet ||
        _cancelled ||
        _retriedCount >= self.maxRetryCount ||
        _currentIndex >= _alternativeURLs.count - 1) {
        return NO;
    }
    return YES;
}

- (void)retry
{
#if __has_include("BDBaseInternal.h")
    BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"download|retry|currentIndex:%tu|retryCount:%tu|url:%@", _currentIndex, _retriedCount, _currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
    NSLog(@"[BDWebImageToB] download|retry|currentIndex:%tu|retryCount:%tu|url:%@", _currentIndex, _retriedCount, _currentRequestURL.absoluteString);
#endif

    self.error = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[BDWebImageManager sharedManager] requestImage:self];
    });
}

- (void)failedWithError:(NSError *)error
{
    self.error = error;
    
    if ([self canRetryWithError:error]) {
        if (self.alternativeURLs.count &&
            _currentIndex < self.alternativeURLs.count - 1) {
            _currentIndex++;
            [self setCurrentRequestURL:self.alternativeURLs[_currentIndex]];
            [self retry];
            return;
        }
        
        if ([BDWebImageRequest needRetryByHttps:error.code] && [self.currentRequestURL.absoluteString hasPrefix:@"http://"]) {
            NSURL *httpsURL = [NSURL URLWithString:[@"https:" stringByAppendingString:self.currentRequestURL.resourceSpecifier]];
            [self setCurrentRequestURL:httpsURL];
            _retriedCount++;
            [self retry];
            return;
        }
        
        if (self.error.code == NSURLErrorTimedOut) {
            _retriedCount++;
            [self retry];
            return;
        }
    }
    
    [self _callbackWithImage:nil data:nil from:BDWebImageResultFromNone];
}

- (void)finishWithImage:(UIImage *)image
                   data:(NSData *)data
               savePath:(NSString *)savePath
                    url:(NSURL *)url
                   from:(BDWebImageResultFrom)from
{
    if (_cancelled) {
        return;
    }

//    多个request复用同一个下载url后，会使用真实下载url进行回调，抖音上有判断 url 的逻辑导致出错，这里注释原有逻辑改成返回 原请求url
//    if (url && ![url isEqual:self.currentRequestURL]) {
//        [self setCurrentRequestURL:url];
//        if (![_alternativeURLs containsObject:_currentRequestURL]) {
//            _currentIndex = NSNotFound;
//        }
//    }
    if (from == BDWebImageResultFromDownloading) {
        [self setProgress:1.0];
    } else {
        _progress = 1.0;
    }
    
    self.image = image;
    self.data = data;
    _endTime = CACurrentMediaTime();
    _retriedCount = 0;
    self.cachePath = savePath;
    [self _callbackWithImage:image data:data from:from];
}

- (void)thumbnailFinished:(UIImage *)image from:(BDWebImageResultFrom)from
{
    if (!image || self.image || self.isFinished || _cancelled) {
        return;
    }
    image.bd_requestKey = self.originalKey;
    if (self.completedBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.cancelled && !self.isFinished && self.completedBlock && image && !self.image) {
                if (ENABLE_LOG) {
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"HeicProgressDecodeThumbnail:url:%@ Call Complete Block", self.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] HeicProgressDecodeThumbnail:url:%@ Call Complete Block", self.currentRequestURL.absoluteString);
#endif
                }
                BDImageRequestTimestamp(self,thumbOverallEndTime);
                self.completedBlock(self, image, nil, nil, from);
            }
        });
    }
}
#pragma mark - private Method

- (void)_callbackWithImage:(UIImage *)image
                      data:(NSData *)data
                      from:(BDWebImageResultFrom)from
{
    _finished = YES;
    
    NSString *result = nil;
    if (self.error != nil) {
        result = [NSString stringWithFormat:@"fail|errorCode:%ld|errorDesc:%@", (long)self.error.code, self.error.localizedDescription];
    } else {
        result = [NSString stringWithFormat:@"success|size:%tu", data.length];
    }

    if (ENABLE_LOG) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"overAllEnd|%@|from:%zd|url:%@", result, from, self.currentRequestURL.absoluteString);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] overAllEnd|%@|from:%zd|url:%@", result, from, self.currentRequestURL.absoluteString);
#endif
    }

    if (!self.cancelled && self.performanceBlock) {
        if ([image isKindOfClass:NSClassFromString(@"BDImage")]) {
            self.recorder.codeType = [[image valueForKey:@"codeType"] integerValue];
        }
        BDImageRequestTimestamp(self,overallEndTime);
        if ([BDWebImageRequest isMonitorDecodedImageQuality]) {
            NSInteger result = [BDWebImageUtil isWhiteOrBlackImage:image
                                                     samplingPoint:self.randomSamplingPointCount];
            switch (result) {
                case 1:
                    self.recorder.isDecodeImageQualityAbnormal = @"black_suspected";
                    break;
                case 2:
                    self.recorder.isDecodeImageQualityAbnormal = @"white_suspected";
                    break;
                case 3:
                    self.recorder.isDecodeImageQualityAbnormal = @"transparent_suspected";
                    break;
                default:
                    self.recorder.isDecodeImageQualityAbnormal = @"";
                    break;
            }
        }
        
        self.recorder.error = self.error;
        self.recorder.originalImageSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale);
        self.recorder.imageURL = self.currentRequestURL;
        self.performanceBlock(self.recorder);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.largeImageMonitor trackLargeImageMonitor];
        });
    }

    if (self.completedBlock && !_cancelled) {
        if (self.option & BDImageRequestCallbackNotInMainThread) {
            if (pthread_main_np()) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (!self.cancelled && self.completedBlock) {
                        self.completedBlock(self, self.image, self.data, self.error,from);
                    }
                });
            } else {
                self.completedBlock(self, self.image, _data, _error, from);
            }
        } else {
            if (pthread_main_np()) {
                self.completedBlock(self, self.image, _data, _error,from);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!self.cancelled && self.completedBlock) {
                        self.completedBlock(self, self.image, self.data, self.error, from);
                    }
                });
            }
        }
    }
}

#pragma mark - extension Private Method

- (void)_setReceivedSize:(int64_t)receivedSize andExpectedSize:(int64_t)expectedSize
{
    if (expectedSize) {
        _receivedSize = receivedSize;
        _expectedSize = expectedSize;
        [self setProgress:(double)_receivedSize / expectedSize];
    }
}

- (void)_receiveProgressData:(NSData *)currentReceiveData
                    finished:(BOOL)finished
                   taskQueue:(dispatch_queue_t)queue
                        task:(id<BDWebImageDownloadTask>)task
{
    //这里调用比较频繁，在多图片情况下，会有内存爆炸问题「SD也存在类似的情况」因此可以考虑使用时间换空间的做法
    if ((self.option & BDImageAnimatedImageProgressiveDownload) &&
        (!isAnimatedImageData(currentReceiveData))) {
        return;
    }
    if (_needUpdateProgress) {
        if (self.option & BDImageStaticImageProgressiveDownload) {
            _needUpdateProgress = NO;
            
            if (task.expectedSize == task.receivedSize){
                return;
            }
            
            BDImageCodeType type;
            Class decoderClaz = [BDImageDecoderFactory decoderForImageData:currentReceiveData type:&type];
            if (![decoderClaz supportStaticProgressDecode:type]) {
                return;
            }
            NSData *imageData = [currentReceiveData copy];
            NSURL *currentURL = [self.currentRequestURL copy];
            dispatch_async(queue, ^{
                NSError *error = nil;
                
                if (task.expectedSize == task.receivedSize){
                    return;
                }
                
                id<BDImageDecoder> decoder = [[decoderClaz alloc] initWithIncrementalData:imageData config:self.config];
                self.image = [[BDImage alloc] initWithCoderInternal:decoder];
               
                UIImage *realImage = nil;
                if ([self.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)]) {
                    realImage = [self.transformer transformImageBeforeStoreWithImage:self.image];
                } else {
                    realImage = self.image;
                }
                realImage.bd_requestKey = self.originalKey;
                realImage.bd_webURL = currentURL;
                realImage.bd_loading = YES;//Progressive

                if (self.image && self.completedBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!self.cancelled && self.completedBlock) {
                            self.completedBlock(self, realImage, imageData, error, BDWebImageResultFromDownloading);
                        }
                    });
                }
                
            });
        } else if ((self.option & BDImageProgressiveDownload) || (self.option & BDImageAnimatedImageProgressiveDownload)) {
            _needUpdateProgress = NO;
            
            BDImageCodeType type;
            Class decoderClaz = [BDImageDecoderFactory decoderForImageData:currentReceiveData type:&type];
            if (![decoderClaz supportProgressDecode:currentReceiveData]) {
                return;
            }
            NSData *imageData = [currentReceiveData copy];
            NSURL *currentURL = [self.currentRequestURL copy];
            dispatch_async(queue, ^{
                NSError *error = nil;
                if (!self.image) {
                    id<BDImageDecoder> decoder = [[decoderClaz alloc] initWithIncrementalData:imageData config:self.config];
                    self.image = [[BDImage alloc] initWithCoderInternal:decoder];
                } else {
                    if ([self.image isKindOfClass:[BDImage class]]) {
                        [(BDImage *)self.image changeImageWithData:imageData finished:finished];
                    }
                }
                UIImage *realImage = nil;
                if ([self.transformer respondsToSelector:@selector(transformImageBeforeStoreWithImage:)]) {
                    realImage = [self.transformer transformImageBeforeStoreWithImage:self.image];
                }else {
                    realImage = self.image;
                }
                realImage.bd_requestKey = self.originalKey;
                realImage.bd_webURL = currentURL;
                realImage.bd_loading = YES;//Progressive
                
                if (self.image && self.completedBlock) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!self.cancelled && self.completedBlock) {
                            self.completedBlock(self, realImage, imageData, error, BDWebImageResultFromDownloading);
                        }
                    });
                }
            });
        }
    }
}

#pragma mark - Getter

- (BDImageDecoderConfig *)config {
    if (_config == nil) {
        _config = [BDImageDecoderConfig new];
        _config.decodeForDisplay = ((self.option & BDImageNotDecoderForDisplay) == 0);
        _config.scale = BDScaledFactorForKey(self.currentRequestURL.absoluteString);
        _config.downsampleSize = self.downsampleSize;
        _config.cropRect = self.smartCropRect;
    }
    return _config;
}

//- (BOOL)_needUpdateProgress {
//    return ABS(self->_progress - _lastNotifiedProgress) > _minNotifiProgressInterval;
//}

#pragma mark - Setter

- (void)setProgress:(double)progress
{
    BOOL needNotifi = NO;
    if (ABS(progress - _lastNotifiedProgress) > _minNotifiProgressInterval) {
        needNotifi = YES;
    }
    _progress = progress;
//    _tempLastNotifiedProgress = _lastNotifiedProgress;
    if (needNotifi) {
        _lastNotifiedProgress = _progress;
        _needUpdateProgress = YES;
        if (self.progressBlock) {
            if (pthread_main_np()) {
                self.progressBlock(self,self.receivedSize,self.expectedSize);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!self.cancelled && self.progressBlock) {
                        self.progressBlock(self,self.receivedSize,self.expectedSize);
                    }
                });
            }
        }
    }
}

- (void)setRequestKey:(NSString *)requestKey
{
    _requestKey = requestKey;
    _originalKey.sourceKey = requestKey;
    _originalKey.builded = YES;
    self.recorder.identifier = requestKey;
}

- (NSString *)requestKey
{
    if (_originalKey.builded && _originalKey.sourceKey.length > 0) {
        return _originalKey.sourceKey;
    }
    return _requestKey;
}

- (void)setCategory:(NSString *)category
{
    _category = category;
    self.recorder.category = category;
}

- (void)setCurrentRequestURL:(NSURL *)currentRequestURL
{
    if ([currentRequestURL isKindOfClass:NSString.class]) {
        _currentRequestURL = [NSURL URLWithString:(NSString *)currentRequestURL];
    } else if([currentRequestURL isKindOfClass:NSURL.class]) {
        _currentRequestURL = currentRequestURL;
    }
}

- (void)setOption:(BDImageRequestOptions)option
{
    _option = option;
    if ((option & BDImageRequestSmartCorp) == BDImageRequestSmartCorp) {
        _originalKey.smartCrop = YES;
    }
}

- (void)setDownsampleSize:(CGSize)downsampleSize
{
    _downsampleSize = downsampleSize;
    if (!CGSizeEqualToSize(downsampleSize, CGSizeZero)) {
        _originalKey.downsampleSize = downsampleSize;
        _downsampleSize = _originalKey.downsampleSize;
    }
}

- (void)setupKeyAndTransformer:(BDBaseTransformer *)transformer
{
    self.transformer = transformer;
    if (transformer.appendingStringForCacheKey.length > 0) {
        _originalKey.transfromName = transformer.appendingStringForCacheKey;
    }
}



#pragma mark - Static

+ (NSMutableArray *)defaultRetryErrorCodes
{
    static NSMutableArray *retryCodes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        retryCodes = [[NSMutableArray alloc] initWithCapacity:5];
        [retryCodes addObject:@(BDWebImageCheckTypeError)];
        [retryCodes addObject:@(BDWebImageCheckDataLength)];
        [retryCodes addObject:@(NSURLErrorZeroByteResource)];
        [retryCodes addObject:@(-324)];//错误码 -324 对应 TTNet 的错误 EMPTY_RESPONSE
        [retryCodes addObject:@(-102)];//错误码 -102 对应 TTNet 的错误 A connection attempt was refused.
    });
    return retryCodes;
}

+ (void)addRetryErrorCode:(NSInteger)code
{
    NSMutableArray *codes = [self defaultRetryErrorCodes];
    if (![codes containsObject:@(code)]) {
        [codes addObject:@(code)];
    }
}

+ (void)removeRetryErrorCode:(NSInteger)code
{
    NSMutableArray *codes = [self defaultRetryErrorCodes];
    [codes removeObject:@(code)];
}

+ (BOOL)needRetryByHttps:(NSInteger)code
{
    NSMutableArray *codes = [self defaultRetryErrorCodes];
    BOOL isRetry = NO;
    if ([codes containsObject:@(code)]) {
        isRetry = YES;
    }
    return isRetry;
}

#pragma mark - Large Image Monitor Settings

static BOOL bd_isMonitorLargeImage = NO;

+ (BOOL)isMonitorLargeImage
{
    return bd_isMonitorLargeImage;
}

+ (void)setIsMonitorLargeImage:(BOOL)isMonitorLargeImage
{
    bd_isMonitorLargeImage = isMonitorLargeImage;
}

static NSUInteger bd_largeImageFileSizeLimit = 0;

+ (void)setLargeImageFileSizeLimit:(NSUInteger)fileSizeLimit
{
    bd_largeImageFileSizeLimit = fileSizeLimit;
}

+ (NSUInteger)largeImageFileSizeLimit
{
    return bd_largeImageFileSizeLimit;
}

static NSUInteger bd_largeImageMemoryLimit = 0;

+ (void)setLargeImageMemoryLimit:(NSUInteger)largeImageMemoryLimit
{
    bd_largeImageMemoryLimit = largeImageMemoryLimit;
}

+ (NSUInteger)largeImageMemoryLimit
{
    return bd_largeImageMemoryLimit;
}

#pragma mark - Decode Image Quality Monitor Settings

static BOOL bd_isMonitorDecodedImageQuality = NO;

+ (BOOL)isMonitorDecodedImageQuality
{
    return bd_isMonitorDecodedImageQuality;
}

+ (void)setIsMonitorDecodedImageQuality:(BOOL)isMonitorDecodedImageQuality
{
    bd_isMonitorDecodedImageQuality = isMonitorDecodedImageQuality;
}

@end
