//
//  BDImagePerformanceRecoder.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import "BDImagePerformanceRecoder.h"
#import "BDWebImageManager+Private.h"
#import "BDWebImageRequest.h"
#import "BDWebImageError.h"
#import "BDWebImageMacro.h"

#ifdef BDWebImage_POD_VERSION
static NSString *const kBDWebImagePodVersion = BDWebImage_POD_VERSION;
#else
static NSString *const kBDWebImagePodVersion = @"";
#endif

@interface BDImagePerformanceRecoder ()
@property(weak, readwrite) BDWebImageRequest *request;
@end


@implementation BDImagePerformanceRecoder

- (instancetype)initWithRequest:(BDWebImageRequest * _Nullable)request {
    if(self = [super init]) {
        self.request = request;
    }
    return self;
}
    
- (double)queueDuration
{
    double duration = 0.0;
    // 排队时间先判断是否存在有效的缓存查询时间，如果存在则是计算缓存查找结束到下载开始的时间段；否则计算整体开始到下载开始的时间段
    if (self.cacheSeekDuration > 0) {
         duration = [self validIntervalFromBegin:_cacheSeekEndTime toEnd:_downloadStartTime];
    }
    else {
        duration = [self validIntervalFromBegin:_overallStartTime toEnd:_downloadStartTime];
    }
    if (duration < 0.0) {
        duration = 0.0;
    }
    return duration;
}

- (double)downloadDuration
{
    return [self validIntervalFromBegin:_downloadStartTime toEnd:_downloadEndTime];
}

- (double)cacheSeekDuration
{
    return [self validIntervalFromBegin:_cacheSeekStartTime toEnd:_cacheSeekEndTime];
}

- (double)thumbCacheSeekDuration
{
    return [self validIntervalFromBegin:_thumbCacheSeekStartTime toEnd:_thumbCacheSeekEndTime];
}

- (double)decodeDuration
{
    return [self validIntervalFromBegin:_decodeStartTime toEnd:_decodeEndTime];
}

- (double)thumbDecodeDuration
{
    return [self validIntervalFromBegin:_thumbDecodeStartTime toEnd:_thumbDecodeEndTime];
}

- (double)cacheImageDuration
{
    return [self validIntervalFromBegin:_cacheImageBeginTime toEnd:_cacheImageEndTime];
}

- (double)overallDuration
{
    return [self validIntervalFromBegin:_overallStartTime toEnd:_overallEndTime];
}

- (double)repackDuration
{
    return [self validIntervalFromBegin:_repackStartTime toEnd:_repackEndTime];
}

- (double)thumbDownloadDuration
{
    return [self validIntervalFromBegin:_downloadStartTime toEnd:_thumbDownloadEndTime];
}

- (double)thumbFindLocationDuration
{
    return [self validIntervalFromBegin:_downloadStartTime toEnd:_thumbFindLocationEndTime];
}

- (double)thumbOverallDuration
{
    return [self validIntervalFromBegin:_overallStartTime toEnd:_thumbOverallEndTime];
}

- (double)validIntervalFromBegin:(double)begin toEnd:(double)end {
    if (end > 0 && begin > 0 && (end > begin)) {
        return end - begin;
    }
    
    return -1;
}

#ifdef DEBUG
- (NSString *)description
{
#if 0
    NSLog(@" allStart:%.1lf\n cacheStart:%.1lf\n cacheEnd:%.1lf\n downloadStart:%.1lf\n downloadEnd:%.1lf\n decodeStart:%.1lf\n decodeEnd:%.1lf\n allEnd:%.1lf\n",
          _overallStartTime, _cacheSeekStartTime, _cacheSeekEndTime, _downloadStartTime, _downloadEndTime, _decodeStartTime, _decodeEndTime, _overallEndTime);
    NSLog(@"all:%.1lf", _overallEndTime-_overallStartTime);
    NSLog(@"queryCache:%.1lf", _cacheSeekEndTime-_cacheSeekStartTime);
    NSLog(@"queue:%.1lf", _downloadStartTime-_overallStartTime);
    NSLog(@"download:%.1lf", _downloadEndTime-_downloadStartTime);
    NSLog(@"decode:%.1lf", _decodeEndTime-_decodeStartTime);
    NSLog(@"cacheImage:%.1lf", _cacheImageEndTime-_cacheImageBeginTime);
    NSLog(@"other:%.1lf", _overallEndTime-_cacheImageEndTime);
    NSLog(@"calculateAll:%.1f", (_cacheSeekEndTime-_cacheSeekStartTime + _downloadStartTime-_cacheSeekEndTime+_downloadEndTime-_downloadStartTime+ _decodeEndTime-_decodeStartTime+_overallEndTime-_cacheImageEndTime));
#endif

    NSString *desc = [NSString stringWithFormat:@"request identifier:%@, category:%@, timeStamp:%0.lf, options:%zd, thumbCacheSeekDuration:%g ms, cacheSeekDuration:%g ms, cacheType:%tu, queueDuration:%g ms, thumbDownloadDuration:%g ms downloadDuration:%g ms (DNSDuration:%zd ms, connetDuration:%zd ms, sslDuration:%zd ms, sendDuration:%zd ms, waitDuration:%zd ms, receiveDuration:%zd ms), fileSize:%g byte, imageSize: %g X %g, codeType:%tu, repackDuration:%g ms,thumbDecodeDuration:%g ms, decodeDuration:%g ms, cacheImageDuration:%g ms, thumbFindLocationDuration:%g ms, thumbDuration:%g ms, overallDuration:%g ms",self.identifier, self.category, self.timeStamp, self.options, self.thumbCacheSeekDuration, self.cacheSeekDuration, self.cacheType, self.queueDuration, self.thumbDownloadDuration, self.downloadDuration,  self.DNSDuration.integerValue, self.connetDuration.integerValue, self.sslDuration.integerValue, self.sendDuration.integerValue, self.waitDuration.integerValue, self.receiveDuration.integerValue, self.totalBytes, self.originalImageSize.width, self.originalImageSize.height, self.codeType, self.repackDuration, self.thumbDecodeDuration, self.decodeDuration, self.cacheImageDuration, self.thumbFindLocationDuration, self.thumbOverallDuration, self.overallDuration];
    
    return desc;
}
#endif

- (NSDictionary<NSString *, id> * _Nullable)imageMonitorV2Log {
    __strong __kindof BDWebImageRequest * _Nullable request = self.request;
    
    DEBUG_ASSERT(request != nil);
    
    NSUInteger imageCount = 0;
    if ([request.image isKindOfClass:[BDImage class]]) {
        BDImage *image = (BDImage *)request.image;
        imageCount = image.frameCount;
    } else if (request.image) {
        imageCount = 1;
    }
    
    NSString *imageType = imageTypeString(self.codeType);
    if ([imageType isEqualToString:@"unknow"]) {
        if ([self.mimeType hasPrefix:@"image/"]) {
            imageType = [self.mimeType substringFromIndex:6];
        }
    }else if ([imageType isEqualToString:@"webp"] && ((BDImage *)request.image).isAnimateImage) {
        imageType = @"awebp";
    }
    
    // 修正版本号，去除appid前缀(13_0.4.0-rc.3)
    NSString *sdkVersion = kBDWebImagePodVersion;
    NSRange underLineRange = [sdkVersion rangeOfString:@"_"];
    if (underLineRange.location != NSNotFound) {
        sdkVersion = [sdkVersion substringFromIndex:underLineRange.location+1];
    }
    
    NSMutableDictionary *attributes = [@{
                                         @"file_size": @(self.totalBytes),
                                         @"intended_image_size": [NSString stringWithFormat:@"%zd*%zd", (NSInteger)self.requestImageSize.width, (NSInteger)self.requestImageSize.height],
                                         @"applied_image_size": [NSString stringWithFormat:@"%zd*%zd", (NSInteger)self.originalImageSize.width, (NSInteger)self.originalImageSize.height],
                                         @"duration": @((NSInteger)self.overallDuration),
                                         @"queue_duration": @((NSInteger)self.queueDuration),
                                         @"download_duration": @((NSInteger)self.downloadDuration),
                                         @"decode_duration": @((NSInteger)self.decodeDuration),
                                         @"thumb_decode_duration": @((NSInteger)self.thumbDecodeDuration),
                                         @"thumb_file_size": @((NSInteger)self.thumbBytes),
                                         @"thumb_find_location_duration": @((NSInteger)self.thumbFindLocationDuration),
                                         @"thumb_download_duration": @((NSInteger)self.thumbDownloadDuration),
                                         @"thumb_cache_seek_duration": @((NSInteger)self.thumbCacheSeekDuration),
                                         @"thumb_repack_duration": @((NSInteger)self.repackDuration),
                                         @"image_type": imageType ?: @"",
                                         @"image_sdk_version": sdkVersion ?: @"",
                                         @"log_version": @(1),
                                         @"server_ip": self.remoteIP ?: @"",
                                         @"load_status": (self.error ? @"fail":@"success"),
                                         @"http_status": @(self.statusCode),
                                         @"timestamp": @((NSInteger)self.timeStamp),
                                         @"uri": self.imageURL.absoluteString ?: @"",
                                         @"cache_seek_duration": @((NSInteger)self.cacheSeekDuration),
                                         @"download_impl": @([BDWebImageManager sharedManager].downloadImpl),
                                         @"exception_tag": @(self.exceptionType),
                                         @"image_count": @(imageCount),
                                         @"hit_cdn_cache": self.isHitCDNCache ?: @"",
                                         @"imagex_consistency": self.imageXConsistent ?: @"",
                                         @"imagex_want_fmt": self.imageXWantedFormat ?: @"undefined",
                                         @"imagex_true_fmt": self.imageXRealGotFormat ?: @"undefined",
                                         @"image_quality": self.isDecodeImageQualityAbnormal ?: @"undefined",
                                         @"view_size":[NSString stringWithFormat:@"%zd*%zd", (NSInteger)self.viewSize.width, (NSInteger)self.viewSize.height],
                                         } mutableCopy];
    if (self.responseHeaders != nil){
        attributes[@"headers"] = self.responseHeaders;
    }
    if (self.error != nil) {
        attributes[@"err_code"] = @(self.error.code);
        attributes[@"err_desc"] = self.error.localizedDescription ?: @"";
        if (self.error.code == BDWebImageBadImageData || self.error.code == BDWebImageEmptyImage) {
            attributes[@"fail_phase"] = @"decode";
        } else {
            attributes[@"fail_phase"] = @"download";
        }
    }
    if (self.nwSessionTrace != nil) {
        attributes[@"nw-session-trace"] = self.nwSessionTrace;
    }
    
    if (self.imageXDemotion != nil){
        attributes[@"imagex_demotion"] = self.imageXDemotion;
    }else{
        attributes[@"imagex_demotion"] = @"undefined";
    }
    
    if (self.codeType == BDImageCodeTypeHeic || self.codeType == BDImageCodeTypeHeif ) {
        if ([request.image isKindOfClass:[BDImage class]]) {
            attributes[@"heic_sys_first"] = @([BDWebImageManager sharedManager].isSystemHeicDecoderFirst);
            attributes[@"heic_custom_decoder"] = @(((BDImage *)request.image).isCustomHeicDecoder);
        }
    }
    
    if (request.bizTag.length > 0) {
        attributes[@"biz_tag"] = request.bizTag;
    } else if ([BDWebImageManager sharedManager].bizTagURLFilterBlock) {
        NSString *bizTag = [BDWebImageManager sharedManager].bizTagURLFilterBlock(self.imageURL);
        if (bizTag != nil && [bizTag isKindOfClass:[NSString class]]) {
            attributes[@"biz_tag"] = bizTag;
        }
    }
    
    if (request.sceneTag.length > 0){
        attributes[@"scene_tag"] = request.sceneTag;
    } else if ([BDWebImageManager sharedManager].sceneTagURLFilterBlock) {
        NSString *sceneTag = [BDWebImageManager sharedManager].sceneTagURLFilterBlock(self.imageURL);
        if (sceneTag != nil && [sceneTag isKindOfClass:[NSString class]]) {
            attributes[@"scene_tag"] = sceneTag;
        }
    }
    
    NSMutableDictionary *net_timing_detail = [NSMutableDictionary dictionaryWithCapacity:15];
    if (nil != self.connetDuration) {
        net_timing_detail[@"timing_connect"] = self.connetDuration;
    }
    if (nil != self.DNSDuration) {
        net_timing_detail[@"timing_dns"] = self.DNSDuration;
    }
    if (nil != self.isCached) {
        net_timing_detail[@"timing_isCached"] = self.isCached;
    }
    if (nil != self.isFromProxy) {
        net_timing_detail[@"timing_isFromProxy"]  = self.isFromProxy;
    }
    if (nil != self.isSocketReused) {
        net_timing_detail[@"timing_isSocketReused"] = self.isSocketReused;
    }
    if (nil != self.receiveDuration) {
        net_timing_detail[@"timing_receive"] = self.receiveDuration;
    }
    if (nil != self.remoteIP) {
        net_timing_detail[@"timing_remoteIP"] = self.remoteIP;
    }
    if (nil != self.remotePort) {
        net_timing_detail[@"timing_remotePort"] = self.remotePort;
    }
    if (nil != self.sendDuration) {
        net_timing_detail[@"timing_send"] = self.sendDuration;
    }
    if (nil != self.sslDuration) {
        net_timing_detail[@"timing_ssl"] = self.sslDuration;
    }
    net_timing_detail[@"timing_total"] = @((NSInteger)self.downloadDuration);
    net_timing_detail[@"timing_totalReceivedBytes"] = @((NSInteger)self.receivedBytes);
    if (nil != self.waitDuration) {
        net_timing_detail[@"timing_wait"] = self.waitDuration;
    }
    if (self.requestLog != nil) {
        net_timing_detail[@"request_log"] = self.requestLog;
    }
    attributes[@"net_timing_detail"] = [net_timing_detail copy];
    
    if (request.transformer) {
        NSDictionary *transformerRecoder = [request.transformer transformImageRecoder];
        if (transformerRecoder.count > 0) {
            [attributes addEntriesFromDictionary:transformerRecoder];
        }
    }
    
    return attributes;
}

@end
