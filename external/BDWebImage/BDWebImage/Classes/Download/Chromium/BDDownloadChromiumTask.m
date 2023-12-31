//
//  BDDownloadChromiumTask.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/4.
//

#import "BDDownloadTask+Private.h"
#import "BDDownloadChromiumTask.h"
#import "BDDownloadChromiumTask+Private.h"
#import "BDWebImageManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <objc/runtime.h>
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import "BDWebImageError.h"


@interface BDDownloadChromiumTask()

@property (nonatomic, strong) NSProgress *downloadProgress;
@property (nonatomic, assign) int64_t expectedSize;
@property (nonatomic, assign) NSInteger realSize;           ///< 当开启了 heic 渐进式式 repack 能力的时候需要用于存储真实下载的 data size
@property (nonatomic, strong) NSMutableData *imageData;

@end

@implementation BDDownloadChromiumTask

@dynamic expectedSize;
@synthesize realSize;
@synthesize task = _task;

#pragma mark - LifeCycle
- (void)dealloc {
    [self.task cancel];
    self.task = nil;
    if (self.downloadProgress) {
        [self.downloadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(completedUnitCount))];
        [self.downloadProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(totalUnitCount))];
    }
}

#pragma mark - Override Method

- (BDDownloadTask *)initWithURL:(NSURL *)url {
    return [super initWithURL:url];
}

- (void)start {
    [super start];
    [self startDownload];
}

- (void)_cancel {
    [self.task cancel];
    self.task = nil;
}

#pragma mark - Privare Method

- (void)startDownload {
    if ([self.url.scheme isEqualToString:@"data"] || [self.url.scheme isEqualToString:@"file"]) {
        NSData *data = [NSData dataWithContentsOfURL:self.url];
        [self setFinished:YES];
        if (data) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:finishedWithData:savePath:)]) {
                [self.delegate downloadTask:self finishedWithData:data savePath:nil];
            }
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:failedWithError:)]) {
            [self.delegate downloadTask:self
                        failedWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                   code:NSURLErrorZeroByteResource
                                                               userInfo:@{NSLocalizedDescriptionKey:@"download data is empty"}]];
        }
        return;
    }
    
    __autoreleasing NSProgress *progress = nil;
    __weak typeof(self) weakSelf = self;
    if (!self.task) {
        NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:self.url
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:0];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPShouldUsePipelining = YES;
        [request setValue:[BDWebImageManager sharedManager].adaptiveDecodePolicy forHTTPHeaderField:@"Accept"];
        [self.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        [self.requestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        self.request = [request copy];

        __block BOOL hasContentLength = YES;
        self.task = [[TTNetworkManager shareInstance] requestForChunkedBinaryWithResponse:self.url.absoluteString params:nil method:@"GET" needCommonParams:NO headerField:self.request.allHTTPHeaderFields enableHttpCache:NO requestSerializer:nil responseSerializer:nil autoResume:NO headerCallback:^(TTHttpResponse *response) {
            if (response.allHeaderFields[kHTTPResponseContentLength]) {
                NSString *httpContentLength = response.allHeaderFields[kHTTPResponseContentLength];
                weakSelf.expectedSize = [httpContentLength integerValue];
                if (weakSelf.imageData == nil) {
                    weakSelf.imageData = [[NSMutableData alloc] initWithCapacity:weakSelf.expectedSize];
                }
                hasContentLength = YES;
            } else {
                if (weakSelf.imageData == nil) {
                    weakSelf.imageData = [[NSMutableData alloc] init];
                }
                hasContentLength = NO;
            }
        } dataCallback:^(NSData *obj) {
            if (hasContentLength && obj.length + weakSelf.imageData.length > weakSelf.expectedSize &&
                (weakSelf.isProgressiveDownload || weakSelf.needHeicProgressDownloadForThumbnail)) {
                NSError *error = [[NSError alloc] initWithDomain:@"BDWebImage" code:BDWebImageOverFlowExpectedSize userInfo:nil];
                [weakSelf callbackActionWithError:error Obj:nil response:nil];
                [weakSelf cancel];
                return;
            }
            [weakSelf.imageData appendData:obj];
            if (!hasContentLength) {// 部分图片采用边解压边传输，Content-Length没有值，无法设置进度，如链接：https://sf1-ttcdn-tos.pstatp.com/obj/developer/app/tt33de4563acf4bffc/icon4d97f6e?1560681269118
                weakSelf.expectedSize = weakSelf.imageData.length;
            }
            
            [weakSelf _setReceivedSize:weakSelf.imageData.length  expectedSize:weakSelf.expectedSize];
            
            if (weakSelf.isProgressiveDownload || weakSelf.needHeicProgressDownloadForThumbnail) {
                [weakSelf.delegate downloadTask:weakSelf didReceiveData:weakSelf.imageData finished:hasContentLength && weakSelf.expectedSize == weakSelf.imageData.length];
            }
        } callbackWithResponse:^(NSError *error, id obj, TTHttpResponse *response) {
            __strong typeof(self) strongSelf = weakSelf;
            

            if (strongSelf.enableLog) {
                if ([response isKindOfClass:[TTHttpResponseChromium class]]) {
                    TTHttpResponseChromiumTimingInfo *info = ((TTHttpResponseChromium *)response).timingInfo;
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|response|dns:%lld, connect:%lld, ssl:%lld, send:%lld, wait:%lld, receive:%lld, ip:%@, port:%d, trace:%@, url:%@", info.dns, info.connect, info.ssl, info.send, info.wait, info.receive, info.remoteIP, info.remotePort, response.allHeaderFields[@"nw-session-trace"], strongSelf.url.absoluteString);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] download|response|dns:%lld, connect:%lld, ssl:%lld, send:%lld, wait:%lld, receive:%lld, ip:%@, port:%d, trace:%@, url:%@", info.dns, info.connect, info.ssl, info.send, info.wait, info.receive, info.remoteIP, info.remotePort, response.allHeaderFields[@"nw-session-trace"], strongSelf.url.absoluteString);
#endif
                }
            }
            
            if (strongSelf) {
                if ([response isKindOfClass:[TTHttpResponseChromium class]]) {
                    TTHttpResponseChromiumTimingInfo *info = ((TTHttpResponseChromium *)response).timingInfo;
                    strongSelf.DNSDuration = @(info.dns);
                    strongSelf.connetDuration = @(info.connect);
                    strongSelf.sslDuration = @(info.ssl);
                    strongSelf.sendDuration = @(info.send);
                    strongSelf.waitDuration = @(info.wait);
                    strongSelf.receiveDuration = @(info.receive);
                    strongSelf.isSocketReused = @(info.isSocketReused);
                    strongSelf.isCached = @(info.isCached);
                    strongSelf.isFromProxy = @(info.isFromProxy);
                    strongSelf.remoteIP = info.remoteIP;
                    strongSelf.remotePort = @(info.remotePort);
                    strongSelf.statusCode = response.statusCode;
                    strongSelf.mimeType = response.MIMEType;
                    
                    [strongSelf responseCache:response];
                    
                    if (class_getProperty([TTHttpResponseChromium class], "requestLog")) {
                        Ivar var = class_getInstanceVariable([TTHttpResponseChromium class], "_requestLog");
                        NSString *requestLog = object_getIvar(response, var);
                        if ([requestLog isKindOfClass:[NSString class]]) {
                            strongSelf.requestLog = requestLog;
                        }
                    }
                }
            }
            [strongSelf setupSmartCropRectFromHeaders:response.allHeaderFields];
            NSInteger dataSizeBias = 0;
            if (strongSelf.imageData.length > 0 && [BDWebImageManager sharedManager].enableRepackHeicData) {
                strongSelf.realSize = strongSelf.imageData.length;
                [strongSelf repackStart];
                BOOL repackPreCheck = (strongSelf.isThumbnailExist == BDDownloadThumbnailNotDetermined)&&[strongSelf.delegate respondsToSelector:@selector(isRepackNeeded:)]&&[strongSelf.delegate respondsToSelector:@selector(heicRepackData:)];
                BOOL needRepackForThumbnailUnknow = repackPreCheck && [strongSelf.delegate isRepackNeeded:strongSelf.imageData];

                if ((strongSelf.isThumbnailExist == BDDownloadThumbnailExist) || needRepackForThumbnailUnknow) {
                    NSMutableData *repackedData = [strongSelf.delegate heicRepackData:strongSelf.imageData];
                    if (repackedData.length > 0 && repackedData.length <= strongSelf.imageData.length) {
                        dataSizeBias = strongSelf.imageData.length - repackedData.length;
                        strongSelf.imageData = repackedData;
                    }
                }
                [strongSelf repackEnd];
            }
            NSError *dataError = [strongSelf checkDataError:error data:strongSelf.imageData dataSizeBias:dataSizeBias headers:response.allHeaderFields];
            [strongSelf callbackActionWithError:error?:dataError Obj:strongSelf.imageData response:response];
        }];
    }

    if (self.task) {
        if (self.queuePriority == NSOperationQueuePriorityHigh) {
            [self.task setPriority:1.f];
        } else if (self.queuePriority == NSOperationQueuePriorityLow){
            [self.task setPriority:0.25f];
        } else {
            [self.task setPriority:0.75f];
        }
        if ([self isCancelled]) {
            self.finished = YES;
        } else {
            if (progress) {
                self.downloadProgress = progress;
                [self.downloadProgress addObserver:self forKeyPath:NSStringFromSelector(@selector(completedUnitCount)) options:NSKeyValueObservingOptionNew context:nil];
                [self.downloadProgress addObserver:self forKeyPath:NSStringFromSelector(@selector(totalUnitCount)) options:NSKeyValueObservingOptionNew context:nil];
            }
        }
        self.task.timeoutInterval = self.timeoutInterval ?: 15;
        [self.task resume];
    } else {
        self.finished = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:failedWithError:)]) {
            [self.delegate downloadTask:self
                        failedWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorBadURL
                                                        userInfo:@{NSLocalizedDescriptionKey:@"failed to create download request"}]];
        }
    }
}

- (void)callbackActionWithError:(NSError *)error Obj:(id)obj response:(TTHttpResponse *)response {
    dispatch_async([self creat_complete_handle_queue], ^{
        [self setFinished:YES];

        NSData *data = nil;
        if (obj && [obj isKindOfClass:[NSData class]]) {
            data = obj;
        }
        if (!error && data && data.length > 0) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:finishedWithData:savePath:)]) {
                [self.delegate downloadTask:self finishedWithData:data savePath:nil];
            }
        } else {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSUInteger code = ((NSHTTPURLResponse *)response).statusCode;
                if (code == 304) {
                    [super cancel];
                }
            }

            if (self.delegate && [self.delegate respondsToSelector:@selector(downloadTask:failedWithError:)]) {
                [self.delegate downloadTask:self
                            failedWithError:error?:[NSError errorWithDomain:NSURLErrorDomain
                                                                       code:NSURLErrorZeroByteResource
                                                                   userInfo:@{NSLocalizedDescriptionKey:@"download data is empty"}]];
            }
        }
    });

}

#pragma mark -- KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.downloadProgress) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(completedUnitCount))]) {
            NSNumber *completedUnitCountValue = [change valueForKey:NSKeyValueChangeNewKey];
            long long receivedSize = completedUnitCountValue.longLongValue;
            [self _setReceivedSize:receivedSize expectedSize:self.expectedSize];
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(totalUnitCount))]) {
            NSNumber *totalUnitCountValue = [change valueForKey:NSKeyValueChangeNewKey];
            self.expectedSize = totalUnitCountValue.longLongValue;
        }
    }
}

#pragma mark - download completed queue
- (dispatch_queue_t) creat_complete_handle_queue{
    static dispatch_queue_t complete_handle_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self.isCocurrentCallback) {
            complete_handle_queue = dispatch_queue_create("tt_network_complete_handle_concurrent_queue", DISPATCH_QUEUE_CONCURRENT);
        }
        else {
            complete_handle_queue = dispatch_queue_create("tt_network_complete_handle_serial_queue", DISPATCH_QUEUE_SERIAL);
        }
    });
    return complete_handle_queue;
}

#pragma mark - response header
-(void)responseCache:(TTHttpResponse *)response{
    self.nwSessionTrace = response.allHeaderFields[@"nw-session-trace"];
    
    if (response.allHeaderFields[kHTTPResponseCache] != nil){
        self.responseHeaders = @{kHTTPResponseCache:response.allHeaderFields[kHTTPResponseCache]};
    }
    if (response.allHeaderFields[kHTTPResponseCacheControl] != nil) {
        self.cacheControlTime = [BDDownloadTask getCacheControlTimeFromResponse:response.allHeaderFields[kHTTPResponseCacheControl]];
    }
    
    // 是否命中CDN缓存
    // 判断X-Cache-new、X-Cache、X-Cache-Status、via、X-Via-Ucdn是否存在
    NSString *cacheString = nil;
    if (response.allHeaderFields[@"X-Cache"] != nil){
        cacheString = @"X-Cache";
    }else if (response.allHeaderFields[@"X-Cache-new"] != nil){
        cacheString = @"X-Cache-new";
    }else if (response.allHeaderFields[@"X-Cache-Status"] != nil){
        cacheString = @"X-Cache-Status";
    }else if (response.allHeaderFields[@"via"] != nil){
        cacheString = @"via";
    }else if (response.allHeaderFields[@"X-Via-Ucdn"] != nil){
        cacheString = @"X-Via-Ucdn";
    }
    if (cacheString != nil){
        self.isHitCDNCache = [[response.allHeaderFields[cacheString] lowercaseString] containsString:@"hit"] ? @(1) : @(0);
    }else{
        self.isHitCDNCache = @(-1);
    }
    
    // 是否降级
    self.imageXDemotion = response.allHeaderFields[kHTTPImageXDemotion];
    
    // 请求的图片格式 & 真实获取的图片格式
    self.imageXWantedFormat = @"undefined";
    self.imageXRealGotFormat = @"undefined";
    NSString *imageXFmt = response.allHeaderFields[kHTTPImageXFmt];
    if (imageXFmt != nil){
        NSArray *arr = [imageXFmt componentsSeparatedByString:@"2"];
        if (arr.count == 2){
            self.imageXWantedFormat = arr[0];
            self.imageXRealGotFormat = arr[1];
        }
    }
    
    // 比较请求的图片格式 & 真实获取的图片格式
    if (([self.imageXRealGotFormat isEqual: @"undefined"]) || ([self.imageXRealGotFormat isEqual: @"undefined"] )){
        self.imageXConsistent = @(-1);
    }else{
        self.imageXConsistent = [self.imageXRealGotFormat isEqual:self.imageXRealGotFormat] ? @(1) : @(0);
    }
}

@end
