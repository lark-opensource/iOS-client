//
//  TTVideoFetcherWrapper.m
//  Pods
//
//  Created by 钟少奋 on 2017/4/10.
//
//

#import "TTVideoEngineInfoFetcher.h"
#include <iostream>
#include "TTVideoPreloader.h"

@interface TTVideoFetcherWrapper : NSObject

@property (atomic, assign) BOOL isLoading;
@property (nonatomic, assign) AVVideoInfo *videoInfo;

- (instancetype)initWithMetaURL:(NSString *)metaURL resolution:(int)resolution;
- (void)cancel:(void *)context;

@end

typedef struct URLFetcher{
    TTVideoFetcherWrapper *fetcher;
    URLFetcher(): fetcher(nil){};
}AVVideoURLContex;

void *TTPreloaderGetVideoUrl(const char *metaUrl, int resolution,void* user)
{
    TTVideoFetcherWrapper *fetchWrapper = [[TTVideoFetcherWrapper alloc] initWithMetaURL:[NSString stringWithUTF8String:metaUrl]
                                                                              resolution:resolution];
    AVVideoURLContex *contex = new AVVideoURLContex;
    contex->fetcher = fetchWrapper;
    return contex;
}

bool TTPreloaderGetFetchVideoUrlLoadingStatus(void *ctx)
{
    AVVideoURLContex *contex = (AVVideoURLContex *)ctx;
    return contex->fetcher.isLoading;
}

AVVideoInfo *TTPreloaderGetVideoUrlInfo(void *ctx)
{
    AVVideoURLContex *contex = (AVVideoURLContex *)ctx;
    return contex->fetcher.videoInfo;
}

void TTPreloaderReleaseVideoUrlCtx(void *ctx)
{
    AVVideoURLContex *contex = (AVVideoURLContex *)ctx;
    contex->fetcher = nil;
    delete contex;
    contex = nullptr;
}

void TTPreloaderCancleFetchVideoUrl(void *ctx)
{
    AVVideoURLContex *contex = (AVVideoURLContex *)ctx;
    [contex->fetcher cancel:ctx];
}

@interface TTVideoFetcherWrapper() <TTVideoInfoFetcherDelegate>

@property (nonatomic, strong) TTVideoEngineInfoFetcher *fetcher;
@property (nonatomic, assign) int resolution;
@property (nonatomic, unsafe_unretained) void *context;

@end

@implementation TTVideoFetcherWrapper

- (instancetype)initWithMetaURL:(NSString *)metaURL resolution:(int)resolution
{
    self = [super init];
    if (self) {
        _fetcher = [[TTVideoEngineInfoFetcher alloc] init];
        _fetcher.delegate = self;
        
        _resolution = resolution;
        _videoInfo = nullptr;
    }
    
    _isLoading = YES;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_fetcher fetchInfoWithAPI:metaURL parameters:nil auth:nil];
    });
    
    return self;
}

- (void)dealloc
{
    if(self.videoInfo != nullptr) {
        if(self.videoInfo->vid != nullptr) {
            delete self.videoInfo->vid;
            self.videoInfo->vid = nullptr;
        }
        if(self.videoInfo->url != nullptr) {
            delete self.videoInfo->url;
            self.videoInfo->url = nullptr;
        }
        delete self.videoInfo;
        self.videoInfo = nullptr;
    }
}

- (void)cancel:(void *)context
{
    self.context = context;
    [self.fetcher cancel];
}

- (void)infoFetcherDidFinish:(NSInteger)status {
    self.isLoading = NO;
}

- (void)infoFetcherDidFinish:(TTVideoEngineModel *)videoModel error:(NSError *)error
{
    TTVideoEngineURLInfo *urlInfo = [videoModel videoInfoForType:(TTVideoEngineResolutionType)self.resolution];
    int originIndex = self.resolution;
    while (!urlInfo) {
        self.resolution = (self.resolution + 4)%5;
        urlInfo = [videoModel videoInfoForType:(TTVideoEngineResolutionType)self.resolution];
        if (urlInfo || self.resolution == originIndex) {
            break;
        }
    }
    
    if (!urlInfo) {
        self.isLoading = NO;
        return;
    }
    
    AVVideoInfo *videoInfo = new AVVideoInfo;
    NSString *videoID = [videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
    char *vid = new char[videoID.length + 1];
    if (videoID.length) {
        strcpy(vid, videoID.UTF8String);
    }
    videoInfo->vid = vid;
    
    char *url = new char[[urlInfo getValueStr:VALUE_MAIN_URL].length + 1];
    if ([urlInfo getValueStr:VALUE_MAIN_URL].length) {
        strcpy(url, [urlInfo getValueStr:VALUE_MAIN_URL].UTF8String);
    }
    videoInfo->url = url;
    
    videoInfo->preloadSize = [urlInfo getValueNumber:VALUE_PRELOAD_SIZE].intValue;
    videoInfo->resolution = [urlInfo getVideoDefinitionType];
    videoInfo->supportedResolution = [self getSupportedResolution:videoModel];
    self.videoInfo = videoInfo;
    self.isLoading = NO;
}

- (int32_t)getSupportedResolution:(TTVideoEngineModel *)videoModel
{
    int32_t resolutionMask = 0;
    
    NSArray<NSNumber *> *types = [videoModel.videoInfo supportedResolutionTypes];
    for (NSNumber *item in types) {
        [self setResolutionMask:&resolutionMask forResolution:(TTVideoEngineResolutionType)[item integerValue]];
    }
    return resolutionMask;
}

- (void)setResolutionMask:(int32_t *)mask forResolution:(TTVideoEngineResolutionType)resolution {
    switch (resolution) {
        case TTVideoEngineResolutionTypeUnknown:
            *mask |= 1<<0;
            break;
        case TTVideoEngineResolutionTypeSD:
            *mask |= 1<<1;
            break;
        case TTVideoEngineResolutionTypeHD:
            *mask |= 1<<2;
            break;
        case TTVideoEngineResolutionTypeFullHD:
            *mask |= 1<<3;
            break;
        case TTVideoEngineResolutionType1080P:
            *mask |= 1<<4;
            break;
        case TTVideoEngineResolutionType4K:
            *mask |= 1<<5;
            break;
        default:
            break;
    }
}

- (void)infoFetcherFinishWithDNSError:(NSError *)error
{
    self.isLoading = NO;
}

- (void)infoFetcherDidCancel {
    TTPreloaderReleaseVideoUrlCtx(self.context);
}
- (void)infoFetcherShouldRetry:(NSError *)error {}

@end
