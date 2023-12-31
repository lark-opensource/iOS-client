//
//  BDDownloadTask.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDDownloadTask.h"
#import "BDDownloadTask+Private.h"
#import "BDDownloadManager+Private.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import <CommonCrypto/CommonDigest.h>
#import "BDWebImageError.h"
#import "BDImageDecoderFactory.h"

NSString *const kBDDownloadTaskInfoHTTPResponseHeaderKey = @"HTTPResponseHeader";
NSString *const kBDDownloadTaskInfoHTTPRequestHeaderKey = @"HTTPRequestHeader";
NSString *const kBDDownloadTaskInfoOriginalURLKey = @"OriginalURL";
NSString *const kBDDownloadTaskInfoCurrentURLKey = @"CurrentURL";
NSString *const kHTTPResponseCacheControl = @"cache-control";
NSString *const kHTTPResponseContentLength = @"Content-Length";
NSString *const kHTTPResponseContentType = @"Content-Type";
NSString *const kHTTPResponseImageMd5 = @"X-Md5";
NSString *const kHTTPResponseImageXLength = @"X-Length";
NSString *const kHTTPResponseImageXCropRs = @"X-Crop-Rs"; // 图片服务下发的图片Header带智能裁剪的区域，区域左上角坐标-右下角坐标：(0,256)-(556,812)
NSString *const kHTTPResponseCache = @"x-response-cache";
NSString *const kHTTPImageXDemotion = @"ImageX-Demotion";
NSString *const kHTTPImageXFmt = @"ImageX-Fmt";

@interface BDDownloadTask ()
{
    BOOL _finished;
    BOOL _executing;
}

@property (nonatomic, assign, readwrite) double repackStartTime;
@property (nonatomic, assign, readwrite) double repackEndTime;
@property (nonatomic, assign, readwrite) double startTime;
@property (nonatomic, assign, readwrite) double finishTime;
@property (nonatomic, assign, readwrite) int64_t expectedSize;
@property (nonatomic, assign, readwrite) int64_t receivedSize;

@end

@implementation BDDownloadTask

@synthesize url = _url;
@synthesize identifier;
@synthesize request;
@synthesize smartCropRect = _smartCropRect;
@synthesize timeoutInterval;
@synthesize timeoutIntervalForResource;
@synthesize isThumbnailExist;
@synthesize minDataLengthForThumbnail;
@synthesize needHeicProgressDownloadForThumbnail;
@synthesize isHeicThumbDecodeFired;
@synthesize realSize;

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)setFinished:(BOOL)finished
{
    if (finished != _finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        if (_finished) {
            self.finishTime = CACurrentMediaTime() * 1000;
            if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
                BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|end|url:%@", self.url.absoluteString);
#elif __has_include("BDBaseToB.h")
                NSLog(@"[BDWebImageToB] download|end|url:%@", self.url.absoluteString);
#endif
            }
        }
        [self setExecuting:!finished];
        [self didChangeValueForKey:@"isFinished"];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

- (void)setExecuting:(BOOL)executing
{
    if (executing != _executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)asynchronous
{
    return YES;
}

- (void)repackStart
{
    self.repackStartTime = CACurrentMediaTime() * 1000;
}

- (void)repackEnd
{
    self.repackEndTime = CACurrentMediaTime() * 1000;
}

- (void)start
{
    if (self.isCancelled)
    {
        [self setFinished:YES];
        if ([self.delegate respondsToSelector:@selector(downloadTaskDidCanceled:)]) {
            [self.delegate downloadTaskDidCanceled:self];
        }
        return;
    }
    [self setExecuting:YES];
    self.startTime = CACurrentMediaTime() * 1000;
    if (self.enableLog) {
#if __has_include("BDBaseInternal.h")
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebImage", @"download|start|url:%@", self.url.absoluteString);
#elif __has_include("BDBaseToB.h")
        NSLog(@"[BDWebImageToB] download|start|url:%@", self.url.absoluteString);
#endif
    }
}

- (void)cancel
{
    if (self.isFinished) return;
    
    [super cancel];
    [self _cancel];
    if (self.executing) [self setFinished:YES];
}

- (void)_setReceivedSize:(int64_t)receivedSize expectedSize:(int64_t)expectedSize
{
    __strong __typeof(self)strongSelf = self;
    self.receivedSize = receivedSize;
    self.expectedSize = expectedSize;
    if ([(id)_delegate respondsToSelector:@selector(downloadTask:receivedSize:expectedSize:)]) {
        [_delegate downloadTask:strongSelf receivedSize:self.receivedSize expectedSize:self.expectedSize];
    }
}

+ (NSInteger) getCacheControlTimeFromResponse:(NSString *)cacheControl {
    NSArray<NSString *> *cacheControlArray = [cacheControl componentsSeparatedByString:@"="];
    if ([cacheControlArray count] == 2) {
        return [cacheControlArray[1] integerValue];
    }
    return 0;
}

/// 将 header 的 智能裁剪区域解析并设置SmartCropRect
/// header 区域左上角坐标-右下角坐标：(0,256)-(556,812) 转换成 CGRect 格式
- (void)setupSmartCropRectFromHeaders:(NSDictionary *)headers {
    NSString *cropRs = headers[kHTTPResponseImageXCropRs];
    if (!cropRs.length) {
        _smartCropRect = CGRectZero;
        return;
    }
    NSCharacterSet* nonDigits =[[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSArray *coordinates = [cropRs componentsSeparatedByString:@"-"];
    NSMutableArray *points = [NSMutableArray arrayWithCapacity:2];
    for (NSString *coordinate in coordinates) {
        NSArray *num = [coordinate componentsSeparatedByString:@","];
        if (num.count == 2) {
            NSInteger x = [[num[0] stringByTrimmingCharactersInSet:nonDigits] intValue];
            NSInteger y = [[num[1] stringByTrimmingCharactersInSet:nonDigits] intValue];
            CGPoint p = CGPointMake(x, y);
            [points addObject:[NSValue valueWithCGPoint:p]];
        }
    }
    if (points.count != 2) {
        _smartCropRect = CGRectZero;
        return;
    }
    CGPoint start = [points[0] CGPointValue];
    CGPoint end = [points[1] CGPointValue];
    if (start.x < end.x && start.y < end.y) {
        _smartCropRect = CGRectMake(start.x, start.y, end.x - start.x, end.y - start.y);
    } else {
        _smartCropRect = CGRectZero;
    }
}

- (NSError *)checkDataError:(NSError *)error data:(NSData *)data dataSizeBias:(NSInteger)dataSizeBias headers:(NSDictionary *)headers {
    NSError *dataError = error;
    NSString *xLength = headers[kHTTPResponseImageXLength];
    NSString *contentType = headers[kHTTPResponseContentType];
    if (error == nil) {
        // 检查下载内容是否是图片类型、长度是否正常，如果不正常可能被挟持，重试https
        BDImageCodeType codeType = BDImageDetectType((__bridge CFDataRef)data);
        // BDWebImageCheckTypeError 的 error 会在 BDWebImageRequest 中将请求换成 https
        if (self.checkMimeType && contentType.length > 0 && codeType == BDImageCodeTypeUnknown) {
            dataError = [[NSError alloc] initWithDomain:@"BDWebImage" code:BDWebImageCheckTypeError userInfo:@{NSLocalizedDescriptionKey: @"download data is not a image type"}];
        } else if (self.checkDataLength && xLength.length > 0 && data.length != xLength.integerValue - dataSizeBias) {
            dataError = [[NSError alloc] initWithDomain:@"BDWebImage" code:BDWebImageCheckDataLength userInfo:@{NSLocalizedDescriptionKey: @"download data is incomplete"}];
        }
    }
    return dataError;
}

+ (BOOL)checkData:(NSData *)data md5:(NSString *)md5 {
    if (!data) {
        return NO;
    }
    CC_MD5_CTX dataMd5;
    CC_MD5_Init(&dataMd5);
    CC_MD5_Update(&dataMd5, data.bytes, (CC_LONG)data.length);
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result, &dataMd5);
    NSMutableString *resultMd5 = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [resultMd5 appendFormat:@"%02x",result[i]];
    }
    return [md5 isEqualToString:resultMd5];
}

@end
