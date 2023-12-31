//
//  BDDownloadURLSessionTask.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/12/4.
//

#import "BDDownloadURLSessionTask.h"
#import "BDDownloadURLSessionTask+Private.h"
#import "BDDownloadTask+Private.h"

NSString *const kBDDownloadTaskInfoURLSessionResumeDataKey = @"ResumeData";

@interface BDDownloadURLSessionTask ()

@property (nonatomic, copy) NSDictionary *HTTPResponseHeaders;
@property (nonatomic, copy) NSDictionary *HTTPRequestHeaders;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSMutableData *imageData;
@property (nonatomic, assign) BOOL hasContentLength;

@end

@implementation BDDownloadURLSessionTask

@synthesize sessionManager = _sessionManager;
@synthesize task = _task;

- (void)dealloc
{
    [self->_task cancel];
    self->_task = nil;
}

- (void)start
{
    [super start];
    if (self.cancelled) {
        return;
    }
    [self resetTask];
}

- (void)_cancel
{
    if (self->_task)
    {
        if (self.receivedSize > 0 && self.downloadResumeEnabled) {
            [(NSURLSessionDownloadTask *)self->_task cancelByProducingResumeData:^(NSData *resumeData) {
                self.resumeData = resumeData;
                [self saveTempInfo];
            }];
        } else {
            [self->_task cancel];
        }
    } else {
        [self saveTempInfo];
    }
}

- (void)resetTask
{
    NSString *infoPath = [self.tempPath stringByAppendingPathExtension:@"cfg"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        [self cleanTempFile];
    } else {
        NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        self->_resumeData = [info objectForKey:kBDDownloadTaskInfoURLSessionResumeDataKey];
    }
    
    if (self->_resumeData && self.downloadResumeEnabled) {
        self->_task = [self.sessionManager.session downloadTaskWithResumeData:self->_resumeData];
        self->_resumeData = nil;
    }
    if (!self->_task) {
        NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:self.url
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:self.timeoutInterval?:30];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPShouldUsePipelining = YES;
//        [request setValue:@"image/webp" forHTTPHeaderField:@"Accept"];
        [self.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        [self.requestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        //这里不能是DownloadSession，因为无法即时获取Data数据，从而无法Progressive的现实数据
        self->_task = [self.sessionManager.session dataTaskWithRequest:request];
    }
    
    if (self->_task)
    {
        if (self.queuePriority == NSURLSessionTaskPriorityHigh) {
            self->_task.priority = NSURLSessionTaskPriorityHigh;
        } else if (self.queuePriority == NSURLSessionTaskPriorityLow){
            self->_task.priority = NSURLSessionTaskPriorityLow;
        } else {
            self->_task.priority = NSURLSessionTaskPriorityDefault;
        }
        if ([self isCancelled]) {
            self.finished = YES;
        } else {
            [self->_task resume];
        }
    } else {
        self.finished = YES;
        [self.delegate downloadTask:self
                   failedWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                       code:NSURLErrorBadURL
                                                   userInfo:@{NSLocalizedDescriptionKey:@"failed to create download request"}]];
    }
}

- (void)saveTempInfo
{
    if ([self->_task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.HTTPResponseHeaders = [(NSHTTPURLResponse *)self->_task.response allHeaderFields];
    }
    self.HTTPRequestHeaders = self->_task.currentRequest.allHTTPHeaderFields;
    if (self.HTTPResponseHeaders) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.tempPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:self.tempPath
                                      withIntermediateDirectories:YES
                                                       attributes:NULL
                                                            error:NULL];
        }
        NSMutableDictionary *headers = [[NSMutableDictionary alloc] init];
        [headers setObject:self.HTTPResponseHeaders forKey:kBDDownloadTaskInfoHTTPResponseHeaderKey];
        if (self.HTTPRequestHeaders) {
            [headers setObject:self.HTTPRequestHeaders forKey:kBDDownloadTaskInfoHTTPRequestHeaderKey];
        }
        [headers setObject:self.url.absoluteString forKey:kBDDownloadTaskInfoOriginalURLKey];
        [headers setObject:self->_task.currentRequest.URL.absoluteString forKey:kBDDownloadTaskInfoCurrentURLKey];
        if (self->_resumeData) {
            [headers setObject:self->_resumeData forKey:kBDDownloadTaskInfoURLSessionResumeDataKey];
        }
        [headers writeToFile:[self.tempPath stringByAppendingPathExtension:@"cfg"] atomically:YES];
    }
}

- (void)cleanTempFile
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.tempPath error:nil];
    [fileManager removeItemAtPath:[self.tempPath stringByAppendingPathExtension:@"cfg"] error:nil];
}

#pragma mark - NSURLSessionDataDelegate
NSInteger inde = 0;
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    self.mimeType = response.MIMEType;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.nwSessionTrace = ((NSHTTPURLResponse *)response).allHeaderFields[@"nw-session-trace"];
        self.statusCode = ((NSHTTPURLResponse *)response).statusCode;
        self.HTTPResponseHeaders = ((NSHTTPURLResponse *)response).allHeaderFields;
        
        if (self.HTTPResponseHeaders[kHTTPResponseCache] != nil){
            self.responseHeaders = @{kHTTPResponseCache:self.HTTPResponseHeaders[kHTTPResponseCache]};
        }
        self.imageXDemotion = self.HTTPResponseHeaders[kHTTPImageXDemotion];
        
        // cdn缓存
        NSString *cacheString = nil;
        if (self.HTTPResponseHeaders[@"X-Cache"] != nil){
            cacheString = @"X-Cache";
        }else if (self.HTTPResponseHeaders[@"X-Cache-new"] != nil){
            cacheString = @"X-Cache-new";
        }else if (self.HTTPResponseHeaders[@"X-Cache-Status"] != nil){
            cacheString = @"X-Cache-Status";
        }else if (self.HTTPResponseHeaders[@"via"] != nil){
            cacheString = @"via";
        }else if (self.HTTPResponseHeaders[@"X-Via-Ucdn"] != nil){
            cacheString = @"X-Via-Ucdn";
        }
        if (cacheString != nil){
            self.isHitCDNCache = [[self.HTTPResponseHeaders[cacheString] lowercaseString] containsString:@"hit"] ? @(1) : @(0);
        }else{
            self.isHitCDNCache = @(-1);
        }
        
        // 请求的图片格式 & 真实获取的图片格式
        self.imageXWantedFormat = @"undefined";
        self.imageXRealGotFormat = @"undefined";
        NSString *imageXFmt = self.HTTPResponseHeaders[kHTTPImageXFmt];
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
    
    //'304 Not Modified' is an exceptional one
    if (![response respondsToSelector:@selector(statusCode)] || (((NSHTTPURLResponse *)response).statusCode < 400 && ((NSHTTPURLResponse *)response).statusCode != 304)) {
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        self.expectedSize = expected;
        self.hasContentLength = expected != 0;
        [self _setReceivedSize:self.receivedSize expectedSize:self.expectedSize];
        if (self->_imageData) {
            self->_imageData = nil;
        }
        self->_imageData = [[NSMutableData alloc] initWithCapacity:expected];
        
    }
    else {
        NSUInteger code = ((NSHTTPURLResponse *)response).statusCode;
        
        //This is the case when server returns '304 Not Modified'. It means that remote image is not changed.
        //In case of 304 we need just cancel the operation and return cached image from the cache.
        if (code == 304) {
            [self _cancel];
        } else {
            [self _cancel];
            [self cleanTempFile];
        }
        if ([self.delegate respondsToSelector:@selector(downloadTask:failedWithError:)]) {
            [self.delegate downloadTask:self failedWithError:[NSError errorWithDomain:NSURLErrorDomain code:((NSHTTPURLResponse *)response).statusCode userInfo:nil]];
        }
    }
    
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self->_imageData appendData:data];
    if (!self.hasContentLength) {// 部分图片采用边解压边传输，Content-Length没有值，无法设置进度
        self.expectedSize = self.imageData.length;
    }
    
    [self _setReceivedSize:self->_imageData.length  expectedSize:self.expectedSize];
    if ([self.delegate respondsToSelector:@selector(downloadTask:didReceiveData:finished:)]) {
        [self.delegate downloadTask:self didReceiveData:self.imageData finished:self.hasContentLength && self.expectedSize == self.imageData.length];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics  API_AVAILABLE(ios(10.0)){
    if (@available(iOS 10.0, *)) {
        for (NSURLSessionTaskTransactionMetrics *metric in metrics.transactionMetrics) {
            if (metric.resourceFetchType != NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad) {
                continue;
            }
            
            self.DNSDuration = @((NSInteger)(([metric.domainLookupEndDate timeIntervalSince1970] - [metric.domainLookupStartDate timeIntervalSince1970]) * 1000));
            self.connetDuration = @((NSInteger)(([metric.connectEndDate timeIntervalSince1970] - [metric.connectStartDate timeIntervalSince1970]) * 1000));
            self.sslDuration = @((NSInteger)(([metric.secureConnectionEndDate timeIntervalSince1970] - [metric.secureConnectionStartDate timeIntervalSince1970]) * 1000));
            self.sendDuration = @((NSInteger)(([metric.requestEndDate timeIntervalSince1970] - [metric.requestStartDate timeIntervalSince1970]) * 1000));
            self.waitDuration =  @((NSInteger)(([metric.responseStartDate timeIntervalSince1970] - [metric.requestEndDate timeIntervalSince1970]) * 1000));
            self.receiveDuration = @((NSInteger)(([metric.responseEndDate timeIntervalSince1970] - [metric.responseStartDate timeIntervalSince1970]) * 1000));
            self.isSocketReused = @(metric.isReusedConnection);
            self.isFromProxy = @(metric.isProxyConnection);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    self.finished = YES;
    
    [self setupSmartCropRectFromHeaders:self.HTTPResponseHeaders];
    // 检查下载内容是否正常，出错重试 https
    NSError *dataError = [self checkDataError:error data:self.imageData dataSizeBias:0 headers:self.HTTPResponseHeaders];
    
    if (dataError || !self->_imageData.length) {
        if ([self.delegate respondsToSelector:@selector(downloadTask:failedWithError:)]) {
            if (!dataError && !self->_imageData.length) {
                dataError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorZeroByteResource userInfo:@{NSLocalizedDescriptionKey:@"download data is empty"}];
            }
            [self.delegate downloadTask:self failedWithError:dataError];
            self->_imageData = nil;
            if (dataError.code == NSURLErrorCancelled) {
                self->_task = nil;
            }
        }
    }else {
        if ([self.delegate respondsToSelector:@selector(downloadTask:finishedWithData:savePath:)]) {
            if ([self.HTTPResponseHeaders valueForKey:kHTTPResponseCacheControl]) {
                self.cacheControlTime = [BDDownloadTask getCacheControlTimeFromResponse:[self.HTTPResponseHeaders valueForKey:kHTTPResponseCacheControl]];
            }
            [self.delegate downloadTask:self finishedWithData:self->_imageData savePath:nil];
        }
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    self.finished = YES;
    NSData *data = [NSData dataWithContentsOfURL:location];
    if ([self.HTTPResponseHeaders valueForKey:kHTTPResponseCacheControl]) {
        self.cacheControlTime = [BDDownloadTask getCacheControlTimeFromResponse:[self.HTTPResponseHeaders valueForKey:kHTTPResponseCacheControl]];
    }
    [self.delegate downloadTask:self finishedWithData:data savePath:location.path];
    self->_task = nil;
    self->_imageData = nil;
    [self cleanTempFile];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes
{
    [self _setReceivedSize:fileOffset expectedSize:expectedTotalBytes];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [self _setReceivedSize:totalBytesWritten expectedSize:totalBytesExpectedToWrite];
}

@end
