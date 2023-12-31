//
//  TTVideoEnginePlayVidSource.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/11.
//

#import "TTVideoEnginePlayVidSource.h"
#import "TTVideoEngineInfoFetcher.h"
#import "NSString+TTVideoEngine.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"

#import <TTPlayerSDK/ttvideodec.h>
#import <TTPlayerSDK/ByteCrypto.h>

@interface TTVideoEnginePlayVidSource ()<TTVideoInfoFetcherDelegate>

@property (nonatomic, strong) TTVideoEngineInfoFetcher *infoFetcher;
@property (nonatomic, assign) TTVideoEngineResolutionType currentResolution;
//每个resolution当前用的是哪条url，默认是0mainUrl
@property (nonatomic, strong) NSMutableArray *resolutionIndexs;
@property (nonatomic,   copy) NSString *usingUrl;
@property (nonatomic,   copy) FetchResult fetchCall;

@property (nonatomic,   copy) NSString *apiString;

@end

@implementation TTVideoEnginePlayVidSource

- (instancetype)init {
    if (self = [super init]) {
        _currentResolution = TTVideoEngineResolutionTypeUnknown;
        _resolutionIndexs = [NSMutableArray array];
        for (int i = 0; i < TTVideoEngineAllResolutions().count + 2; i++) {
            [_resolutionIndexs addObject:@(0)];
        }
    }
    return self;
}

- (NSArray<NSNumber *> *)supportResolutions {
    if (self.fetchData) {
        return self.fetchData.supportedResolutionTypes;
    }
    //
    return nil;
}

- (NSArray<NSString *> *)supportQualityDesc {
    if (self.fetchData) {
        return self.fetchData.supportedQualityInfos;
    }
    //
    return nil;
}

- (TTVideoEngineResolutionType)currentResolution {
    if (self.fetchData) {
        if (_currentResolution == TTVideoEngineResolutionTypeUnknown) {
            return self.autoResolution;
        }
        return _currentResolution;
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (TTVideoEngineResolutionType)autoResolution {
    if (self.fetchData) {
        return [self.fetchData autoResolution];
    }
    //
    return TTVideoEngineResolutionTypeUnknown;
}

- (NSString *)getDynamicType {
    NSString *dynamicType = nil;
    if (self.fetchData) {
        dynamicType = [self.fetchData getValueStr:VALUE_DYNAMIC_TYPE] ?: @"";
    }
    //
    return dynamicType;
}

- (NSString *)currentUrl {
    if (self.usingUrl) {
        return self.usingUrl;
    } else {
        return [self urlForResolution:self.currentResolution];
    }
}

- (BOOL)isMainUrl {
    CODE_ERROR(self.currentUrl == nil)
    return ([self.resolutionIndexs[self.currentResolution] isEqual:@(0)] && self.currentUrl);
}

- (NSString *)urlForResolution:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        //
        TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:&resolution autoMode:YES];
        CODE_ERROR(info == nil)
        if (info == nil) {
            TTVideoEngineLog(@"VideoModel error, data invalid");
        }
        
        //
        NSArray *temArray = [self allUrlsForResolution:&resolution];
        NSInteger temIndex = [self.resolutionIndexs[resolution] integerValue];
        if (temIndex >=0 && temArray && temArray.count > temIndex) {
            self.currentResolution = resolution;
            self.usingUrl = temArray[temIndex];
            return self.usingUrl;
        }
    }
    //
    return nil;
}

- (NSArray<NSString *> *)allUrlsForResolution:(TTVideoEngineResolutionType *)resolution {
    if (self.fetchData) {
        //
        TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:resolution autoMode:YES];
        CODE_ERROR(info == nil)
        if (info == nil) {
            TTVideoEngineLog(@"VideoModel error, data invalid");
        }
        //
        if([self.fetchData getValueInt:VALUE_VIDEO_MODEL_VERSION] == TTVideoEngineVideoModelVersion3){
            NSMutableArray* array = [NSMutableArray arrayWithCapacity:5];
            NSString* mainUrl =  [info getValueStr:VALUE_MAIN_URL];
            NSString* backupUrl =  [info getValueStr:VALUE_BACKUP_URL_1];
            *resolution = [info getVideoDefinitionType];
            if(mainUrl != nil){
                [array addObject:mainUrl];
            }
            if(backupUrl != nil){
                [array addObject:backupUrl];
            }
            if (array != nil && [array count] > 0) {
                return array.copy;
            }
        }
        NSArray *temArray = [self.fetchData allUrlsWithResolution:resolution autoMode:YES];
        return temArray;
    }
    //
    return nil;
}

- (TTVideoEngineURLInfo *)usingUrlInfo {
    return [self _urlInfo];
}

- (TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution mediaType:(NSString *)mediatype{
    if (self.fetchData) {
        TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:&resolution mediaType:mediatype autoMode:YES];
        if (info == nil) {
            TTVideoEngineLog(@"VideoModel error, data invalid");
        }
        self.currentResolution = resolution;
        return info;
    }
    //
    return nil;
}

- (TTVideoEngineURLInfo *)urlInfoForResolution:(TTVideoEngineResolutionType)resolution
                                     mediaType:(NSString *)mediatype
                                        params:(NSDictionary *)params {
    if (self.fetchData) {
        TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:resolution mediaType:mediatype params:params];
        if (info == nil) {
            TTVideoEngineLog(@"VideoModel error, data invalid");
        }
        self.currentResolution = resolution;
        return info;
    }
    //
    return nil;
}

- (NSString *)proxyUrlExtraInfo {
    TTVideoEngineURLInfo *temInfo = [self _urlInfo];
    if (temInfo) {
        NSMutableString *extraInfo = [NSMutableString string];
        [extraInfo appendFormat:@"fileId=%@",temInfo.fieldId?:@""];
        [extraInfo appendFormat:@"&bitrate=%zd",[temInfo getValueInt:VALUE_BITRATE]];
        [extraInfo appendFormat:@"&pcrc=%@",temInfo.p2pVerifyUrl?:@""];
        return extraInfo;
    }
    //
    return nil;
}

- (BOOL)skipToNext {
    if (self.fetchData) {
        TTVideoEngineResolutionType temType = self.currentResolution;
        NSArray *temArray = [self allUrlsForResolution:&temType];
        CODE_ERROR(temType != self.currentResolution)
        NSInteger temIndex = [self.resolutionIndexs[self.currentResolution] integerValue];
        CODE_ERROR(temIndex < 0)
        if (temIndex >= 0) {
            temIndex ++;
            if (temArray && temArray.count > temIndex) {
                self.resolutionIndexs[self.currentResolution] = @(temIndex);
                return YES;
            }
        }
    }
    //
    return NO;
}

- (nullable NSArray<TTVideoEngineURLInfo *> *)getVideoList {
    if (self.fetchData) {
        NSArray<TTVideoEngineURLInfo *> *videoList = [self.fetchData getValueArray:VALUE_VIDEO_LIST];
        return videoList;
    }
    return nil;
}

- (nullable NSString *)mediaFileKey {
    if (self.fetchData) {
        NSString* mediaType = [self.fetchData getValueStr:VALUE_MEDIA_TYPE];
        if(mediaType == nil) {
            mediaType = @"video";
        }
        NSString* vid = self.videoId;
        TTVideoEngineURLInfo *currentUrlInfo = [self _urlInfo];
        NSString* fileHash  = [currentUrlInfo getValueStr:VALUE_FILE_HASH];
        NSString* fileSize = [NSNumberFormatter localizedStringFromNumber:[currentUrlInfo getValueNumber:VALUE_SIZE] numberStyle:NSNumberFormatterNoStyle];
        NSString* resolution = currentUrlInfo.definitionString;
        if([mediaType isEqualToString:@"audio"]) {
            resolution = [currentUrlInfo getValueStr:VALUE_QUALITY];
        }
        if (vid.length ==0 || fileHash.length == 0 || fileSize.length == 0 || resolution.length == 0) {
            return nil;
        }
        NSString* fileKey = nil;
        NSString *temSpade = [currentUrlInfo getValueStr:VALUE_PLAY_AUTH];
        if (temSpade.length > 0) {
            fileKey = [NSString stringWithFormat:@"%@_%@_%@_%@_%@",vid,resolution,fileHash,fileSize,[temSpade ttvideoengine_transformEncode]];
        } else {
            fileKey = [NSString stringWithFormat:@"%@_%@_%@_%@",vid,resolution,fileHash,fileSize];
        }
        return fileKey;
    }
    //
    return nil;
}

- (nullable NSString *)decryptionKey {
    NSString *temSpada = nil;
    //
    if (self.supportDash) {
        NSArray *allResolutions = TTVideoEngineAllResolutions();
        for (int i = 0; i < allResolutions.count; i++) {
            NSNumber *resolution = [allResolutions objectAtIndex:i];
            TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:resolution.integerValue];
            NSString *infoSpada = [info getValueStr:VALUE_PLAY_AUTH];
            if (infoSpada && ![infoSpada isEqualToString:@""]) {
                temSpada = infoSpada;
            }
        }
    } else {
        TTVideoEngineURLInfo * info = [self _urlInfo];
        temSpada = [info getValueStr:VALUE_PLAY_AUTH];
    }
    //
    if (temSpada && temSpada.length > 0) {
        return TTVideoEngineGetDescrptKey(temSpada);
    }
    //
    return nil;
}

- (nullable NSString *)spade_a {
    NSString *temSpada = nil;
    //
    if (self.supportDash) {
        NSArray *allResolutions = TTVideoEngineAllResolutions();
        for (int i = 0; i < allResolutions.count; i++) {
            NSNumber *resolution = [allResolutions objectAtIndex:i];
            TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:resolution.integerValue];
            NSString *infoSpada = [info getValueStr:VALUE_PLAY_AUTH];
            if (infoSpada && ![infoSpada isEqualToString:@""]) {
                temSpada = infoSpada;
            }
        }
    } else {
        TTVideoEngineURLInfo * info = [self _urlInfo];
        temSpada = [info getValueStr:VALUE_PLAY_AUTH];
    }
    //
    return temSpada;
}

//所有的视频源里是否有加密源
- (BOOL)isHaveSpadea {
    BOOL isHaveSpadea = NO;
    NSArray <TTVideoEngineURLInfo *> *videoEngineUrlInfos = [self getVideoList];
    for (int i = 0; i < videoEngineUrlInfos.count; i++) {
        TTVideoEngineURLInfo *info = videoEngineUrlInfos[i];
        if ([info getValueStr:VALUE_PLAY_AUTH].length > 0) {
            isHaveSpadea = YES;
            break;
        }
    }
   return isHaveSpadea;
}

- (NSInteger)videoSizeOfType:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        return [self.fetchData videoSizeForType:resolution];
    }
    //
    return -1;
}

- (NSInteger)videoModelVersion {
    if (self.fetchData) {
        return [self.fetchData getValueInt:VALUE_VIDEO_MODEL_VERSION];
    }
    //
    return NO;
}

-(NSInteger)getValueInt:(NSInteger)key {
    if (self.fetchData) {
        return [self.fetchData getValueInt:key];
    }
    //
    return -1;
}

- (CGFloat)getValueFloat:(int)key {
    if (self.fetchData) {
        return [self.fetchData getValueFloat:key];
    }
    //
    return 0.0f;
}

- (nullable NSString *)getValueStr:(int)key {
    if (self.fetchData) {
        NSString *string = [self.fetchData getValueStr:key];
        if (string && ![string isEqualToString:@""]) {
            return string;
        }
    }
    return nil;
}

- (BOOL)validate {
    if (self.fetchData) {
        NSString *temS = [self.fetchData getValueStr:VALUE_VIDEO_VALIDATE];
        return [temS isEqualToString:@"1"];
    }
    //
    return NO;
}

- (NSString *)videoId {
    return _videoId;
}

- (BOOL)supportSSL {
    if (self.fetchData) {
        return [self.fetchData getValueBool:VALUE_VIDEO_ENABLE_SSL];
    }
    //
    return NO;
}

- (BOOL)isSingleUrl {
    return NO;
}

- (TTVideoEngineRetryStrategy)retryStrategyForRetryCount:(NSInteger)retryCount {
    if (self.fetchData && retryCount > 0) {
        // Has back up url.
        TTVideoEngineResolutionType temType = self.currentResolution;
        NSInteger temIndex = [self.resolutionIndexs[temType] integerValue];
        if (temIndex >=0 && temIndex < [self allUrlsForResolution:&temType].count - 1) {
            CODE_ERROR(temType != self.currentResolution)
            return TTVideoEngineRetryStrategyChangeURL;
        }
    }
    //
    return TTVideoEngineRetryStrategyFetchInfo;
}

- (TTAVPreloaderItem *)preloadItem {
    return nil;
}

- (BOOL)supportDash {
    if (self.fetchData) {
        TTVideoEngineURLInfo *temUrlInfo = [self _urlInfo];
        BOOL tem = [[temUrlInfo getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"dash"] || [[temUrlInfo getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"mpd"];
        return tem;
    }
    //
    return NO;
}

- (BOOL)supportMP4 {
    if (self.fetchData) {
        TTVideoEngineURLInfo *temUrlInfo = [self _urlInfo];
        BOOL tem = [[temUrlInfo getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"mp4"];
        return tem;
    }
    return NO;
}

- (BOOL)supportHLS {
    if (self.fetchData) {
        TTVideoEngineURLInfo *temUrlInfo = [self _urlInfo];
        BOOL tem = [[temUrlInfo getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"hls"];
        return tem;
    }
    return NO;
}

- (BOOL)supportHLSSeamlessSwitch {
    if ([self videoMemString].length <= 0) {
        return NO;
    }
    if ([self supportHLS] && [self enableAdaptive]) {
       return YES;
    }
    return NO;
}

- (BOOL)supportBash {
    if ([self videoMemString].length <= 0) {
        return NO;
    }
    if ([self supportDash] && [[self getDynamicType] isEqualToString:@"segment_base"]) {
        return YES;
    } else if ([self supportMP4] && [self enableAdaptive] && ![self isHaveSpadea]) {
        return YES;
    }
    return NO;
}

- (BOOL)hasVideo {
    if (self.fetchData) {
        return [self.fetchData getValueBool:VALUE_HAS_VIDEO];
    }
    //
    return YES;
}

- (NSInteger)bitrateForDashSourceOfType:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        TTVideoEngineURLInfo *temUrlInfo = [self.fetchData videoInfoForType:resolution];
        NSInteger tem = [temUrlInfo getValueInt:VALUE_BITRATE];
        return tem;
    }
    //
    return 0;
}

- (nullable NSString *)checkInfo:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        TTVideoEngineURLInfo *info = [self.fetchData videoInfoForType:resolution];
        NSString *infoCheckInfo = [info getValueStr:VALUE_CHECK_INFO];
        if (infoCheckInfo && ![infoCheckInfo isEqualToString:@""]) {
            return infoCheckInfo;
        }
    }
    return nil;
}

- (NSInteger)currentUrlIndex {
    NSInteger index = [self.resolutionIndexs[self.currentResolution] integerValue];
    CODE_ERROR(index < 0)
    return index;
}

- (nullable NSString *)refString {
    if (self.fetchData) {
        NSString *string = [self.fetchData getValueStr:VALUE_VIDEO_REF_STRING];
        if (string && ![string isEqualToString:@""]) {
            return string;
        }
    }
    return nil;
}

- (nullable NSString *)barrageMaskUrl {
    NSString *string = nil;
    if (self.fetchData) {
        string = [self.fetchData getValueStr:VALUE_BARRAGE_MASK_URL];
        if (string && ![string isEqualToString:@""]) {
            return string;
        } else {
            TTVideoEngineURLInfo * info = [self _urlInfo];
            string = [info getValueStr:VALUE_BARRAGE_MASK_URL];
        }
    }
    return string;
}

- (nullable NSString *)aiBarrageUrl {
    NSString *string = nil;
    if (self.fetchData) {
        string = [self.fetchData getValueStr:VALUE_AI_BARRAGE_URL];
        if (string.length) {
            return string;
        } else {
            TTVideoEngineURLInfo * info = [self _urlInfo];
            string = [info getValueStr:VALUE_AI_BARRAGE_URL];
        }
    }
    return string;
}

- (nullable NSString *)decodingMode {
    if (self.fetchData) {
        NSString *string = [self.fetchData getValueStr:VALUE_VIDEO_DECODING_MODE];
        if (string && ![string isEqualToString:@""]) {
            return string;
        }
    }
    return nil;
}

- (void)setParamMap:(NSDictionary *)params {
    if (self.fetchData) {
        self.fetchData.params = params;
    }
    //
    return;
}

- (NSString *)mediaFileHashOfType:(TTVideoEngineResolutionType)resolution {
    if (self.fetchData) {
        TTVideoEngineURLInfo *temUrlInfo = [self.fetchData videoInfoForType:resolution];
        return [temUrlInfo getValueStr:VALUE_FILE_HASH];
    }
    //
    return nil;
}

- (BOOL)canFetch {
    return (self.videoId && self.videoId.length > 0);
}

- (void)fetchUrlWithApiString:(ReturnStringBlock)apiString
                         auth:(ReturnStringBlock)authString
                       params:(ReturnDictonaryBlock)params
                   apiVersion:(ReturnIntBlock)apiVersion
                       result:(FetchResult)result {
    CODE_ERROR(self.canFetch == NO)

    [self _resetResolutionIndexs];
    
    self.fetchCall = result;
    
    NSString *temApi = nil; NSString *temAuth = nil; NSDictionary *temParams = nil;
    temApi = !apiString ? nil : apiString(self.videoId);
    temAuth = !authString ? nil : authString(self.videoId);
    temParams = !params ? nil : params(self.videoId);
    
    if (self.useFallbackApi && self.fallbackApi) {
        temApi = self.fallbackApi;
        temAuth = nil;
        temParams = @{@"method": [NSString stringWithFormat:@"%d",TTVideo_getCryptoMethod()],@"useFallbackApi": @"enable"};
        apiVersion = nil;
        
    }
    
    self.apiString = temApi;
    self.infoFetcher = [[TTVideoEngineInfoFetcher alloc] init];
    self.infoFetcher.networkSession = self.netClient;
    self.infoFetcher.delegate = (id<TTVideoInfoFetcherDelegate>)self;
    self.infoFetcher.apiversion = !apiVersion ? 0 : apiVersion(self.videoId);
    self.infoFetcher.cacheModelEnable = self.cacheVideoModelEnable;
    self.infoFetcher.useEphemeralSession = self.useEphemeralSession;
    // send
    [self.infoFetcher fetchInfoWithAPI:temApi parameters:temParams auth:temAuth vid:self.videoId key:self.keyseed];
}

- (void)cancelFetch {
    [self.infoFetcher cancel];
    self.infoFetcher = nil;
}

/// MARK: - TTVideoInfoFetcherDelegate

- (void)infoFetcherDidFinish:(NSInteger)status {
    NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:status userInfo:@{TTVideoEnginePlaySourceErrorStatusKey:@(status)}];
    !self.fetchCall ?: self.fetchCall(YES, nil, error);
}

- (void)infoFetcherDidFinish:(TTVideoEngineModel *)videoModel error:(NSError *)error {
    self.fetchData = videoModel.videoInfo;
    !self.fetchCall ?: self.fetchCall(YES, videoModel, error);
}

- (void)infoFetcherShouldRetry:(NSError *)error {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
    [userInfo addEntriesFromDictionary:@{TTVideoEnginePlaySourceErrorRetryKey:@(YES)}];
    NSError *temError = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    !self.fetchCall ?: self.fetchCall(YES, nil, temError);
}

- (void)infoFetcherDidCancel {
    NSError *error = [NSError errorWithDomain:kTTVideoErrorDomainFetchingInfo code:-1 userInfo:@{TTVideoEnginePlaySourceErrorUserCancelKey:@(YES)}];
    !self.fetchCall ?: self.fetchCall(YES, nil, error);
}

- (void)infoFetcherFinishWithDNSError:(NSError *)error {
    !self.fetchCall ?: self.fetchCall(YES, nil, error);
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayVidSource *tem = (TTVideoEnginePlayVidSource *)object;
        result = [self.videoId isEqualToString:tem.videoId];
    }
    return result;
}

- (instancetype)deepCopy {
    TTVideoEnginePlayVidSource *vidSource = [super deepCopy];
    if (self.fetchData) {
        vidSource.fetchData = self.fetchData;
    }
    vidSource.videoId = self.videoId;
    vidSource.infoFetcher = self.infoFetcher;
    vidSource.currentResolution = self.currentResolution;
    vidSource.usingUrl = self.usingUrl;
    vidSource.resolutionIndexs = [NSMutableArray arrayWithArray:self.resolutionIndexs.copy];
    vidSource.fallbackApi = self.fallbackApi;
    vidSource.keyseed = self.keyseed;
    return vidSource;
}

- (nullable TTVideoEngineURLInfo *)_urlInfo {
    if (self.fetchData) {
        TTVideoEngineURLInfo * temUrlInfo = [self.fetchData videoInfoForType:self.currentResolution];
        //CODE_ERROR(temUrlInfo == nil)
        return temUrlInfo;
    }
    //
    return nil;
}

- (void)_resetResolutionIndexs {
    [self.resolutionIndexs removeAllObjects];
    
    for (int i = 0; i < TTVideoEngineAllResolutions().count + 2; i++) {
        [self.resolutionIndexs addObject:@(0)];
    }
}

@end


@implementation TTVideoEnginePlayLiveVidSource

- (BOOL)isLivePlayback {
    return YES;
}

- (BOOL)isEqual:(id)object {
    BOOL result = [super isEqual:object];
    if (!result) {
        return result;
    }
    
    if (![object isKindOfClass:[self class]]) {
        result = NO;
    } else {
        TTVideoEnginePlayLiveVidSource *tem = (TTVideoEnginePlayLiveVidSource *)object;
        result = [self.videoId isEqualToString:tem.videoId];
    }
    return result;
}

@end

