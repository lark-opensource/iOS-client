//
//  TTVideoEnginePlayBaseSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayBaseSource.h"
#import "NSObject+TTVideoEngine.h"


NSString *const TTVideoEnginePlaySourceErrorUserCancelKey = @"TTVideoEnginePlaySourceErrorUserCancelKey";
NSString *const TTVideoEnginePlaySourceErrorStatusKey = @"TTVideoEnginePlaySourceErrorStatusKey";
NSString *const TTVideoEnginePlaySourceErrorRetryKey = @"TTVideoEnginePlaySourceErrorRetryKey";
NSString *const TTVideoEnginePlaySourceErrorDNSKey = @"TTVideoEnginePlaySourceErrorDNSKey";

@interface TTVideoEnginePlayBaseSource ()

@end

@implementation TTVideoEnginePlayBaseSource

@synthesize resolutionMap = _resolutionMap;

- (instancetype)init {
    if (self = [super init]) {
        _resolutionMap = TTVideoEngineDefaultVideoResolutionMap();
    }
    return self;
}

- (NSDictionary<NSString *,NSNumber *> *)resolutionMap {
    return _resolutionMap;
}

- (void)setResolutionMap:(NSDictionary<NSString *,NSNumber *> *)resolutionMap {
    NSParameterAssert(resolutionMap != nil);
    _resolutionMap = resolutionMap;
}

- (void)setParamMap:(NSDictionary *)params {
    return;
}

/// Support all resolutions,  maybe nil.
- (nullable NSArray<NSNumber *> *)supportResolutions {
    return nil;
}

- (nullable NSArray<NSString *> *)supportQualityDesc {
    return nil;
}

/// The current resolution, maybe unknow.
- (TTVideoEngineResolutionType)currentResolution {
    return TTVideoEngineResolutionTypeUnknown;
}

- (TTVideoEngineResolutionType)autoResolution {
    return TTVideoEngineResolutionTypeUnknown;
}
- (CGFloat)getValueFloat:(int)key {
    return 0.0f;
}

- (NSInteger)getValueInt:(NSInteger)key {
    return -1;
}

-(nullable NSString *)getValueStr:(int)key {
    return nil;
}

- (NSString *)getDynamicType {
    return nil;
}

- (NSString *)currentUrl {
    return nil;
}

- (BOOL)isMainUrl {
    return NO;
}

- (BOOL)isSingleUrl {
    return NO;
}

- (TTAVPreloaderItem *)preloadItem {
    return nil;
}

/// Whether it is live.
- (BOOL)isLivePlayback {
    return NO;
}

/// Whether it is a local file.
- (BOOL)isLocalFile {
    return NO;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    return TTVideoEngineRetryStrategyNone;
}

/// Get the size of media.
- (NSInteger)videoSizeOfType:(TTVideoEngineResolutionType)resolution {
    return -1;
}

- (NSInteger)videoModelVersion {
     return -1;
}

/// Get a url, resolution maybe unknow.
- (nullable NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    return nil;
}

/// Get all urls, resolution must explicit.
- (nullable NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    return nil;
}

- (TTVideoEngineURLInfo *)usingUrlInfo {
    return nil;
}

- (TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution mediaType:(NSString *)mediaType{
    return nil;
}

- (TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution
                                     mediaType:(NSString *)mediatype
                                        params:(NSDictionary *)params {
    return nil;
}

- (nullable NSArray<TTVideoEngineURLInfo *> *)getVideoList {
    return nil;
}

- (NSString *)proxyUrlExtraInfo {
    return nil;
}

- (BOOL)skipToNext {
    return NO;
}

/// Cahce media data need the key.
- (nullable NSString *)mediaFileKey {
    return nil;
}

/// The key of decryption.
- (nullable NSString *)decryptionKey {
    return nil;
}

- (nullable NSString *)spade_a {
    return nil;
}

- (NSString *)videoId {
    return nil;
}

- (BOOL)preloadDataIsExpire {
    return NO;
}

- (BOOL)validate {
    return NO;
}

/// Enable ssl, if YES try use ssl.
- (BOOL)supportSSL {
    return NO;
}

- (BOOL)supportDash {
    return NO;
}

- (BOOL)supportMP4 {
    return NO;
}

- (BOOL)supportHLS {
    return NO;
}

- (BOOL)supportHLSSeamlessSwitch {
    return NO;
}

- (BOOL)supportBash {
    return NO;
}

- (BOOL)enableAdaptive {
    return self.fetchData.enableAdaptive;
}

- (NSString *)videoMemString {
    return self.fetchData.memString;
}

- (BOOL)hasVideo {
    return YES;
}

- (NSInteger)bitrateForDashSourceOfType:(TTVideoEngineResolutionType)resolution {
    return 0;
}

- (NSString *)mediaFileHashOfType:(TTVideoEngineResolutionType)resolution {
    return nil;
}

- (nullable NSString *)checkInfo:(TTVideoEngineResolutionType)resolution {
    return nil;
}

- (NSInteger)currentUrlIndex {
    return -1;
}

- (nullable NSString *)refString {
    return nil;
}

- (nullable NSString *)decodingMode {
    return nil;
}

- (nullable NSString *)barrageMaskUrl {
    return nil;
}

- (nullable NSString *)aiBarrageUrl {
    return nil;
}

/// MARK: - Need fetch video info

- (BOOL)canFetch {
    return NO;
}

- (void)fetchUrlWithApiString:(ReturnStringBlock)apiString  /** api string */
                         auth:(ReturnStringBlock)authString /** auth string */
                       params:(ReturnDictonaryBlock)params  /** params */
                   apiVersion:(ReturnIntBlock)apiVersion
                       result:(FetchResult)result {
    !result ?: result(NO, nil, nil);
}

- (void)cancelFetch {
    return;
}

- (void)setFetchData:(nullable TTVideoEngineInfoModel *)fetchData {
    _fetchData = fetchData;
    //
    CODE_ERROR(self.resolutionMap == nil || self.resolutionMap.count == 0) // need set resolutionMap
    [fetchData setUpResolutionMap:self.resolutionMap];
}

/// Equal
- (BOOL)isEqual:(id)object {
    return [super isEqual:object];
}

- (instancetype)deepCopy {
    TTVideoEnginePlayBaseSource *baseSource = [[[self class] alloc] init];
    if (self.resolutionMap) { /// before fetchData
        baseSource.resolutionMap = self.resolutionMap;
    }
    
    if (self.netClient) {
        baseSource.netClient = self.netClient;
    }
    if (self.fetchData) {
        baseSource.fetchData = self.fetchData;
    }
    baseSource.cacheVideoModelEnable = self.cacheVideoModelEnable;
    baseSource.useFallbackApi = self.useFallbackApi;
    baseSource.useEphemeralSession = self.useEphemeralSession;
    
    return baseSource;
}

- (NSArray *)subtitleInfos {
    return self.fetchData.subtitleInfos;
}

- (BOOL)hasEmbeddedSubtitle {
    return self.fetchData.hasEmbeddedSubtitle;
}

- (NSInteger)getDefaultAudioInfo {
    if (self.fetchData.dynamicVideo) {
        return self.fetchData.dynamicVideo.defaultAudioInfoId;
    } else {
        return -1;
    }
}

@end
