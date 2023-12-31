//
//  TTVideoEngineDownloadTask.m
//  TTVideoEngine
//
//  Created by 黄清 on 2020/3/15.
//

#import <Foundation/Foundation.h>
#import "TTVideoEngineDownloader.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineInfoFetcher.h"
#import "TTVideoNetUtils.h"

#import <TTPlayerSDK/ByteCrypto.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSDictionary *_Nullable s_error_dict(NSError * _Nullable error) {
    if (!error) {
        return nil;
    }
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        info[@"infoString"] = [NSString stringWithFormat:@"%@",error.userInfo];
    }
    return @{@"domain":error.domain?:@"",
             @"code":@(error.code),
             @"info":info.copy};
}

NS_INLINE NSError *_Nullable s_dict_error(NSDictionary * _Nullable dict) {
    if (!dict || dict.count < 1) {
        return nil;
    }
    
    return [NSError errorWithDomain:dict[@"domain"]
                               code:[dict[@"code"] integerValue]
                           userInfo:dict[@"info"]];
}



/// MARK: - TTVideoEngineDownloadURLTask
@interface TTVideoEngineDownloadTask ()
@property (nonatomic, readwrite) int64_t taskIdentifier;
@property (nonatomic, nullable, readwrite, copy) NSString *taskType;
@property (nonatomic, readwrite) int64_t countOfBytesReceived;
@property (nonatomic, readwrite) int64_t countOfBytesExpectedToReceive;
@property (nonatomic, readwrite) TTVideoEngineDownloadState state;
@property (nonatomic, nullable, readwrite, copy) NSError *error;
@property (nonatomic, nullable, readwrite, copy) NSString *availableLocalFilePath;
@property (nonatomic, nullable, readwrite, copy) NSArray *mediaKeys;
@property (nonatomic, nullable, readwrite, copy) NSDictionary *usingUrls;
@property (nonatomic, readwrite) BOOL finished;
@property (nonatomic, readwrite) BOOL canceled;
@property (nonatomic, readwrite) NSMutableDictionary *bytesReceivedMap;
@property (nonatomic, readwrite) NSMutableDictionary *bytesExpectedToReceiveMap;

@property (nonatomic, readwrite, copy, nullable) NSString *videoId;
@property (nonatomic, weak) TTVideoEngineDownloader *downloader;
@property (nonatomic, assign) NSTimeInterval updateTs;
@property (nonatomic, assign) int64_t updateBytesReceived;

- (void)setupBaseFiled;
- (void)receiveError:(NSError *_Nonnull)error;
- (void)downloadEnd;
- (NSDictionary *_Nonnull)jsonDict;
- (void)assignWithDict:(NSDictionary *_Nonnull)dict;
- (BOOL)_shouldRetry:(NSError *)error;

@end

@implementation TTVideoEngineDownloadTask

+ (instancetype _Nullable)taskItem {
    TTVideoEngineDownloadTask *baseTask = [[[self class] alloc] init];
    [baseTask setupBaseFiled];
    return baseTask;
}

- (void)setState:(TTVideoEngineDownloadState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    if (_downloader.delegate != nil &&
        [_downloader.delegate respondsToSelector:@selector(VideoEngineDownloader:downloadTask:stateChanged:)]) {
        [_downloader.delegate VideoEngineDownloader:_downloader downloadTask:self stateChanged:state];
    }
}

- (void)setupBaseFiled {
    _taskIdentifier = -1;
    _taskDescription = nil;
    _countOfBytesReceived = 0;
    _countOfBytesExpectedToReceive = 0;
    _state = TTVideoEngineDownloadStateInit;
    _error = nil;
    _availableLocalFilePath = nil;
    _taskType = @"base_task";
    _finished = NO;
    _updateTs = 0;
    _bytesReceivedMap = [NSMutableDictionary dictionary];
    _bytesExpectedToReceiveMap = [NSMutableDictionary dictionary];
}

- (void)invalidateAndCancel {
    if (self.canceled) {
        TTVideoEngineLog(@"[downloader] task did canceled, self.taskIdentifier = %@",@(self.taskIdentifier));
        return;
    }
    self.canceled = YES;
    self.finished = NO;
    self.state = TTVideoEngineDownloadStateCanceling;
    
    NSArray *mediaKeys = self.mediaKeys;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (!s_array_is_empty(mediaKeys)) {
            for (NSString *key in mediaKeys) {
                [TTVideoEngine _ls_cancelDownloadByKey:key];
                [TTVideoEngine ls_removeFileCacheByKey:key];
            }
        }
        TTVideoRunOnMainQueue(^{
            self.state = TTVideoEngineDownloadStateInit;
            [self.downloader cancelTask:self];
        },YES);
    });
}

- (void)suspend {
    self.state = TTVideoEngineDownloadStateSuspended;
}

- (void)resume {
    self.error = nil;
    self.finished = NO;
    self.updateTs = CACurrentMediaTime();
}

- (void)receiveError:(NSError *_Nonnull)error {
    TTVideoRunOnMainQueue(^{
        TTVideoEngineLog(@"[downloader] task-%p-%@, did receive error: %@",self,self.taskDescription,error);
        NSError *temError = nil;
        NSInteger errorCode = error.code;
        if (errorCode == -5000) {
            errorCode = TTVideoEngineErrorWriteFile;
        }
        else if (errorCode == -3000 || errorCode == -1003) {
            if ([[TTVideoEngineNetWorkReachability shareInstance] currentReachabilityStatus] == TTVideoEngineNetWorkStatusNotReachable) {
                errorCode = TTVideoEngineErrorNetworkNotAvailable;
            }
            else {
                errorCode = TTVideoEngineErrorURLUnavailable;
            }
        }
        else if (errorCode == -4000) {
            errorCode = TTVideoEngineErrorServiceInaccessible;
        }
        
        temError = [NSError errorWithDomain:TTVideoEngineDownloadTaskErrorDomain
                                       code:errorCode
                                   userInfo:error.userInfo];
        self.error = temError;
        if (temError && ![self _shouldRetry:temError]) {
            self.state = TTVideoEngineDownloadStateCompleted;
        }
        [self.downloader task:self completeError:temError];
    }, YES);
}

- (void)downloadEnd {
    TTVideoRunOnMainQueue(^{
        self.error = nil;
        self.state = TTVideoEngineDownloadStateCompleted;
        [self.downloader task:self completeError:nil];
    }, YES);
}

- (BOOL)_shouldRetry:(NSError *)error {
    if (error.code == TTVideoEngineErrorUserCancel ||
        error.code == TTVideoEngineErrorSaveTaskItem ||
        error.code == TTVideoEngineErrorWriteFile ||
        error.code == TTVideoEngineErrorNotEnoughDiskSpace) {
        return NO;
    }
    
    return YES;
}

- (nullable NSString *)availableLocalFilePath {
    return _availableLocalFilePath;
}

- (void)assignWithDict:(NSDictionary *_Nonnull)dict {
    _taskIdentifier = [dict[@"id"] longLongValue];
    _taskDescription = dict[@"des"];
    _countOfBytesReceived = [dict[@"res_size"] longLongValue];
    _updateBytesReceived = _countOfBytesReceived;
    _countOfBytesExpectedToReceive = [dict[@"content_size"] longLongValue];
    _state = [dict[@"state"] integerValue];
    _error = s_dict_error(dict[@"error"]);
    _availableLocalFilePath = dict[@"file_path"];
    _mediaKeys = dict[@"media_keys"];
    _usingUrls = dict[@"use_urls"];
    _finished = [dict[@"finish"] boolValue];
    _canceled = [dict[@"cancel"] boolValue];
    _taskType = dict[@"task_type"];
    _videoId  = dict[@"vid"];
    if (dict[@"bytes_rev_map"]) {
        _bytesReceivedMap = [NSMutableDictionary dictionaryWithDictionary:dict[@"bytes_rev_map"]];
    }
    if (dict[@"bytes_expect_map"]) {
        _bytesExpectedToReceiveMap = [NSMutableDictionary dictionaryWithDictionary:dict[@"bytes_expect_map"]];
    }
}

- (NSDictionary *_Nonnull)jsonDict {
    return @{@"id":@(_taskIdentifier),
             @"des":_taskDescription?:@"",
             @"res_size": @(_countOfBytesReceived),
             @"content_size": @(_countOfBytesExpectedToReceive),
             @"state":@(_state),
             @"error":_error ? s_error_dict(_error) : @{},
             @"file_path": _availableLocalFilePath ?: @"",
             @"media_keys":_mediaKeys ?:@[],
             @"use_urls":_usingUrls ?: @{},
             @"finish":@(_finished),
             @"cancel":@(_canceled),
             @"task_type":_taskType,
             @"vid":_videoId?:@"",
             @"bytes_rev_map":_bytesReceivedMap?:@{},
             @"bytes_expect_map":_bytesExpectedToReceiveMap?:@{}};
}

- (NSDictionary *)_debugInfoString {
    return @{@"id":@(_taskIdentifier),
             @"des":_taskDescription?:@"",
             @"res_size": @(_countOfBytesReceived),
             @"content_size": @(_countOfBytesExpectedToReceive),
             @"state":@(_state)};
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[ %@ ]",self._debugInfoString];
}

@end

/// MARK: -

/// MARK: - TTVideoEngineDownloadURLTask
@interface TTVideoEngineDownloadURLTask ()

@property (nonatomic, copy) NSArray *urls;
@property (nonatomic, copy) NSString *key;

+ (instancetype _Nullable)urlTaskWithKey:(NSString *_Nonnull)key
                                    urls:(NSArray *_Nonnull)urls
                                     vid:(nullable NSString *)vid;

@end

@implementation TTVideoEngineDownloadURLTask
@dynamic videoId;

+ (instancetype _Nullable)taskItem {
    TTVideoEngineDownloadURLTask *urlTask = [[[self class] alloc] init];
    [urlTask setupBaseFiled];
    return urlTask;
}

+ (instancetype _Nullable)urlTaskWithKey:(NSString *_Nonnull)key
                                    urls:(NSArray *_Nonnull)urls
                                     vid:(nullable NSString *)vid {
    if (!s_string_valid(key) || s_array_is_empty(urls)) {
        TTVideoEngineLog(@"[downloader] key or urls invalid");
        return nil;
    }
    TTVideoEngineDownloadURLTask * urlTask = [self taskItem];
    urlTask.key = key;
    urlTask.urls = urls;
    urlTask.videoId = vid ?: @"";
    urlTask.mediaKeys = @[key];
    return urlTask;
}

- (void)updateUrls:(NSArray *)urls {
    if (s_array_is_empty(urls)) {
        return;
    }
    
    _urls = urls;
}

- (void)suspend {
    if (self.canceled) {
        TTVideoEngineLog(@"[downloader] task did canceled");
        return;
    }
    
    if (self.state == TTVideoEngineDownloadStateSuspended ||
        self.state == TTVideoEngineDownloadStateInit  ||
        self.state == TTVideoEngineDownloadStateCompleted) {
        TTVideoEngineLog(@"[downloader] not need suspended, state = %zd",self.state);
        return;
    }
    if (![self.downloader suspended:self]) {
        TTVideoEngineLog(@"[downloader] suspend task, task in waiting, taskIdentifier:%@ ",@(self.taskIdentifier));
        return;
    }
    [super suspend];
    
    for (NSString *key in self.mediaKeys) {
        [TTVideoEngine _ls_cancelDownloadByKey:key];
    }
    
    /// try next.
    [self.downloader tryNextWaitingTask:self];
}

- (void)resume {
    if (self.canceled) {
        TTVideoEngineLog(@"[downloader] task did canceled");
        return;
    }
    
    if (self.state == TTVideoEngineDownloadStateRunning) {
        TTVideoEngineLog(@"[downloader] state is running");
        return;
    }
    
    [super resume];
    if (![self.downloader shouldResume:self]) {
        return;
    }
    
    self.usingUrls = @{self.key:self.urls};
    self.state = TTVideoEngineDownloadStateRunning;
    
    NSString *downloadUrl = [TTVideoEngine _ls_downloadUrl:self.key rawKey:self.videoId urls:self.urls];
    [TTVideoEngine _ls_startDownload:downloadUrl];
    [self.downloader resume:self];
}

- (BOOL)_shouldRetry:(NSError *)error {
    return NO;
}

- (void)setupBaseFiled {
    [super setupBaseFiled];
    
    self.taskType = @"url_task";
}

-(void)assignWithDict:(NSDictionary *_Nonnull)dict {
    [super assignWithDict:dict[@"base_dict"]];
    
    _key = dict[@"key"];
    _urls = dict[@"urls"];
}

- (NSDictionary *_Nonnull)jsonDict {
    return @{@"base_dict":[super jsonDict],
             @"key":_key ?:@"",
             @"urls":_urls?:@[]};
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    
    if (![object isKindOfClass:[TTVideoEngineDownloadURLTask class]]) {
        return NO;
    }
    TTVideoEngineDownloadURLTask *other = (TTVideoEngineDownloadURLTask *)object;
    return [self.key isEqualToString:other.key];
}

@end
/// MARK: -


/// MARK: - TTVideoEngineDownloadVidTask

@interface TTVideoEngineDownloadVidTask ()<TTVideoInfoFetcherDelegate>
@property (nonatomic, assign) TTVideoEngineResolutionType resolution;
@property (nonatomic, assign) TTVideoEngineEncodeType codecType;
@property (nonatomic, assign) BOOL baseDashEnable;
@property (nonatomic, assign) BOOL httpsEnable;

@property (nonatomic, strong, nullable) TTVideoEngineInfoFetcher *fetcher;
/// Video-model info.
@property (nonatomic, strong, nullable) TTVideoEngineModel *videoModel;

@property (nonatomic, assign, readwrite) TTVideoEngineResolutionType currentResolution;

/// Temporary variables
@property (nonatomic, copy, nullable) NSString *apiString;
@property (nonatomic, copy, nullable) NSString *authString;

@property (nonatomic, copy, nullable) NSString *fallbackApi;
@property (nonatomic, copy, nullable) NSString *keyseed;

@property (nonatomic, assign) NSInteger retryCount;

+ (instancetype _Nullable)vidTaskWithVid:(NSString *_Nonnull)vid
                              resolution:(TTVideoEngineResolutionType)resolution
                                   codec:(TTVideoEngineEncodeType)codecType
                                baseDash:(BOOL)baseDashEnable
                                   https:(BOOL)httpsEnable;
+ (instancetype _Nullable)vidTaskWithVideoModel:(TTVideoEngineModel *_Nonnull)videoModel
                                     resolution:(TTVideoEngineResolutionType)resolution;

@end

@implementation TTVideoEngineDownloadVidTask
@dynamic videoId;

+ (instancetype _Nullable)taskItem {
    TTVideoEngineDownloadVidTask *vidTask = [[[self class] alloc] init];
    [vidTask setupBaseFiled];
    return vidTask;
}

+ (instancetype _Nullable)vidTaskWithVid:(NSString *_Nonnull)vid
                              resolution:(TTVideoEngineResolutionType)resolution
                                   codec:(TTVideoEngineEncodeType)codecType
                                baseDash:(BOOL)baseDashEnable
                                   https:(BOOL)httpsEnable {
    NSAssert(s_string_valid(vid), @"videoId is invalid");
    if (!s_string_valid(vid)) {
        TTVideoEngineLog(@"[downloader] videoId is invalid");
        return nil;
    }
    
    TTVideoEngineDownloadVidTask *vidTask = [self taskItem];
    vidTask.videoId = vid;
    vidTask.resolution = resolution;
    vidTask.codecType = codecType;
    vidTask.baseDashEnable = baseDashEnable;
    vidTask.httpsEnable = httpsEnable;
    return vidTask;
}

+ (instancetype _Nullable)vidTaskWithVideoModel:(TTVideoEngineModel *_Nonnull)videoModel
                                     resolution:(TTVideoEngineResolutionType)resolution {
    if (!videoModel) {
        TTVideoEngineLog(@"[downloader] key or urls invalid");
        return nil;
    }
    NSAssert(videoModel.dictInfo, @"need dict object for videoInfo, please use videoModelWithDict: init");
    NSString *vid = [videoModel.videoInfo getValueStr:VALUE_VIDEO_ID];
    NSAssert(s_string_valid(vid), @"videoId is invalid");
    if (!s_string_valid(vid)) {
        TTVideoEngineLog(@"[downloader] videoId is invalid");
        return nil;
    }
    
    TTVideoEngineDownloadVidTask *vidTask = [self taskItem];
    vidTask.videoId = vid;
    vidTask.videoModel = videoModel;
    if ([[videoModel codecType] isEqualToString:@"bytevc2"]) {
        vidTask.codecType = TTVideoEngineByteVC2;
    } else if ([[videoModel codecType] isEqualToString:@"bytevc1"]) {
        vidTask.codecType = TTVideoEngineByteVC1;
    } else {
        vidTask.codecType = TTVideoEngineH264;
    }
    vidTask.baseDashEnable = [[videoModel.videoInfo getValueStr:VALUE_DYNAMIC_TYPE] isEqualToString:@"segment_base"];
    vidTask.httpsEnable = [videoModel.videoInfo getValueBool:VALUE_VIDEO_ENABLE_SSL];
    vidTask.resolution = resolution;
    return vidTask;
}

- (void)setVideoModel:(nullable TTVideoEngineModel *)videoModel {
    _videoModel = videoModel;
    
    if (s_string_valid(_videoModel.videoInfo.fallbackAPI)) {
        _fallbackApi = _videoModel.videoInfo.fallbackAPI;
        TTVideoEngineLog(@"[downloader] set vieoModel , fall back api = %@",_fallbackApi);
    }
    if (s_string_valid(_videoModel.videoInfo.keyseed)) {
        _keyseed = _videoModel.videoInfo.keyseed;
        TTVideoEngineLog(@"[downloader] set vieoModel , keyseed = %@",_keyseed);
    }
}

- (void)invalidateAndCancel {
    if (_fetcher) {
        [_fetcher cancel];
    }
    [super invalidateAndCancel];
}

- (void)suspend {
    if (self.canceled) {
        TTVideoEngineLog(@"[downloader] task did canceled");
        return;
    }
    
    if (self.state == TTVideoEngineDownloadStateSuspended ||
        self.state == TTVideoEngineDownloadStateInit  ||
        self.state == TTVideoEngineDownloadStateCompleted) {
        TTVideoEngineLog(@"[downloader] not need suspended, state = %zd",self.state);
        return;
    }
    if (![self.downloader suspended:self]) {
        TTVideoEngineLog(@"[downloader] suspend task, task in waiting, taskIdentifier:%@ ",@(self.taskIdentifier));
        return;
    }
    [super suspend];
    
    for (NSString *key in self.mediaKeys) {
        [TTVideoEngine _ls_cancelDownloadByKey:key];
    }
    
    ///
    [self.downloader tryNextWaitingTask:self];
}

- (void)resume {
    if (self.canceled) {
        TTVideoEngineLog(@"[downloader] task did canceled");
        return;
    }
    
    if (self.state == TTVideoEngineDownloadStateRunning) {
        TTVideoEngineLog(@"[downloader] state is running");
        return;
    }
    
    [super resume];
    if (![self.downloader shouldResume:self]) {
        return;
    }
    
    self.retryCount = 0;
    self.state = TTVideoEngineDownloadStateRunning;
    
    if (_videoModel && ![_videoModel hasExpired]) {
        TTVideoEngineLog(@"[downloader] resume task. video model fallback = %@",_videoModel.videoInfo.fallbackAPI);
        [self _downloadWithVideoModel:_videoModel];
    } else {
        [self _fetchVideoModel];
    }
}

- (void)receiveError:(NSError *)error {
    if ([self _shouldRetry:error]) {
        self.retryCount++;
        [self _fetchVideoModel];
    }
    else {
        [super receiveError:error];
    }
}

- (BOOL)_shouldRetry:(NSError *)error {
    if (![super _shouldRetry:error]) {
        return NO;
    }
    
    return self.retryCount < 10;
}

- (nullable NSString *)availableLocalFilePath {
    if (self.baseDashEnable) {
        return nil;
    }
    
    if (s_string_valid([self.videoModel.videoInfo getSpade_aForType:self.currentResolution])) {
        return nil;
    }
    
    return [super availableLocalFilePath];
}

- (void)setupBaseFiled {
    [super setupBaseFiled];
    
    self.retryCount = 0;
    self.taskType = @"vid_task";
    self.apiVersion = TTVideoEnginePlayAPIVersion0;
    self.resolution = TTVideoEngineResolutionTypeSD;
}

- (void)assignWithDict:(NSDictionary *_Nonnull)dict {
    [super assignWithDict:dict[@"base_dict"]];

    _codecType = [dict[@"codec_type"] intValue];
    _baseDashEnable = [dict[@"base_dash"] boolValue];
    _httpsEnable = [dict[@"https"] boolValue];
    _boeEnable = [dict[@"boe"] boolValue];
    _resolution = [dict[@"resolution"] integerValue];
    _params = dict[@"param"];
    _resolutionMap = dict[@"resolution_map"];
    _apiVersion = [dict[@"api_version"] integerValue];
    _currentResolution = [dict[@"curr_resolution"] integerValue];
    NSDictionary *videoModelDict = dict[@"video_model"];
    if (videoModelDict && videoModelDict.count > 0) {
        self.videoModel = [TTVideoEngineModel videoModelWithDict:videoModelDict];
    }
}

- (NSDictionary *_Nonnull)jsonDict {
    return @{@"base_dict":[super jsonDict],
             @"codec_type":@(_codecType),
             @"base_dash":@(_baseDashEnable),
             @"https":@(_httpsEnable),
             @"boe":@(_boeEnable),
             @"resolution":@(_resolution),
             @"param":_params ?: @{},
             @"resolution_map":_resolutionMap ?:@{},
             @"api_version":@(_apiVersion),
             @"curr_resolution":@(_currentResolution),
             @"video_model":_videoModel ? [_videoModel dictInfo]: @{}};
}

- (BOOL)isEqual:(id)object {
    if ([super isEqual:object]) {
        return YES;
    }
    
    if (![object isKindOfClass:[TTVideoEngineDownloadVidTask class]]) {
        return NO;
    }
    TTVideoEngineDownloadVidTask *other = (TTVideoEngineDownloadVidTask *)object;
    
    if (self.mediaKeys && other.mediaKeys) {
        return [self.mediaKeys isEqualToArray:other.mediaKeys];
    }
    
    BOOL result = [self.videoId isEqualToString:other.videoId];
    result = result && (self.baseDashEnable == other.baseDashEnable);
    result = result && (self.codecType == other.codecType);
    result = result && (self.resolution == other.resolution);
    return result;
}

/// MARK: - TTVideoInfoFetcherDelegate
- (void)infoFetcherDidFinish:(NSInteger)status {
    NSInteger errorCode = TTVideoEngineErrorResultNotApplicable;
    [self receiveError:s_dict_error(@{@"domain":kTTVideoErrorDomainFetchingInfo,
                                      @"code":@(errorCode),
                                      @"info":@{@"location":@"infoFetcherDidFinish",
                                                @"video_id":self.videoId ?: @"null",
                                                @"video_model": self.videoModel?[self.videoModel description]: @"null",
                                                @"model_state":@(status),
                                                @"api_string":self.apiString ?: @"null",
                                                @"auth_string":self.authString ?:@"null",
                                                @"api_version":@(self.apiVersion)}
                                      })];
}

- (void)infoFetcherDidFinish:(nullable TTVideoEngineModel *)videoModel error:(nullable NSError *)error {
    TTVideoEngineLog(@"[downloader] did fetch video model, videoId is %@ ,error = %@",self.videoId,error);
    
    if (self.state == TTVideoEngineDownloadStateCanceling || self.state == TTVideoEngineDownloadStateCompleted) {
        TTVideoEngineLog(@"[downloader] %@ but state is canceled or completed. state = %zd",self.videoId,self.state);
        return;
    }
    
    if (videoModel) {
        self.videoModel = videoModel;
        if (self.state == TTVideoEngineDownloadStateSuspended) {
            TTVideoEngineLog(@"[downloader] %@  but state is suspended",self.videoId);
            return;
        }
        [self _downloadWithVideoModel:videoModel];
    } else if (error) {
        [self receiveError:s_dict_error(@{@"domain":kTTVideoErrorDomainFetchingInfo,
                                          @"code":@(TTVideoEngineErrorParsingResponse),
                                          @"info":@{@"inner_err_domain":error.domain,
                                                    @"inner_err_code":@(error.code),
                                                    @"inner_err_info":error.userInfo ?: @{},
                                                    @"api_string":self.apiString ?: @"null",
                                                    @"auth_string":self.authString ?:@"null",
                                                    @"api_version":@(self.apiVersion)}
        })];
    }
}

- (void)infoFetcherShouldRetry:(NSError *_Nonnull)error {
    
}

- (void)infoFetcherDidCancel {
    [self receiveError:s_dict_error(@{@"domain":kTTVideoErrorDomainFetchingInfo,
                                      @"code":@(TTVideoEngineErrorUserCancel),
                                      @"info":@{@"cancel":@(YES),
                                                @"api_string":self.apiString ?: @"null",
                                                @"auth_string":self.authString ?:@"null",
                                                @"api_version":@(self.apiVersion)}
    })];
}

- (void)infoFetcherFinishWithDNSError:(NSError *_Nonnull)error {
    
}

/// Private Method.
- (void)_fetchVideoModel {
    _fetcher.delegate = nil;
    _fetcher = nil;
    _fetcher = [[TTVideoEngineInfoFetcher alloc] init];
    _fetcher.retryCount = 3;
    _fetcher.delegate = (id<TTVideoInfoFetcherDelegate>)self;
    _fetcher.networkSession = self.netClient;
    _fetcher.cacheModelEnable = YES;
    _fetcher.apiversion = self.apiVersion;
    _apiString = nil;
    
    if (s_string_valid(self.fallbackApi)) {
        NSString *temApi = nil; NSString *temAuth = nil; NSDictionary *temParams = nil;
        temApi = self.fallbackApi;
        temAuth = nil;
        temParams = @{@"method": [NSString stringWithFormat:@"%d",TTVideo_getCryptoMethod()]};
        _fetcher.apiversion = 0;
        temApi = TTVideoEngineBuildHttpsApi(temApi);
        _apiString = temApi;
        // send
        [_fetcher fetchInfoWithAPI:temApi parameters:temParams auth:temAuth vid:self.videoId key:self.keyseed];
    }
    else {
        
        if (self.apiStringCall) {
            _apiString = self.apiStringCall(self.apiVersion, self.videoId);
        }
        _authString = nil;
        if (self.authCall) {
            _authString = self.authCall(self.apiVersion,self.videoId);
        }
        
        NSDictionary *param = @{@"codec_type":(self.codecType == TTVideoEngineByteVC2 ? @"4":(self.codecType == TTVideoEngineByteVC1 ? @"3":@"0")),
                                @"format_type":(self.baseDashEnable ? @"dash" : @"mp4"),
                                @"ssl":(self.httpsEnable ? @"1" : @"0")};
        NSString *apiString = _apiString;
        if (self.boeEnable) {
            apiString = TTVideoEngineBuildBoeUrl(_apiString);
        }
        apiString = TTVideoEngineBuildHttpsApi(apiString);
        [_fetcher fetchInfoWithAPI:apiString parameters:param auth:_authString vid:self.videoId key:nil];
    }
}

- (BOOL)_downloadWithUrlInfo:(TTVideoEngineURLInfo *)urlInfo {
    NSArray *urls = [urlInfo allURLForVideoID:self.videoId transformedURL:NO];
    NSString *fileKey = [urlInfo getValueStr:VALUE_FILE_HASH];
    if (s_array_is_empty(urls) || !s_string_valid(fileKey)) {
        [self receiveError:s_dict_error(@{@"domain":kTTVideoErrorDomainFetchingInfo,
                                          @"code":@(TTVideoEngineErrorResultNotApplicable),
                                          @"info":@{@"using_resolution":@(self.currentResolution),
                                                    @"urls":urls ?: @"null",
                                                    @"file_hash":fileKey?:@"null"
                                          }
        })];
        return NO;
    }
    TTVideoEngineLog(@"[downloader] download urlInfo, videoId = %@, resolution = %@, fileHash = %@",
                     self.videoId,@(urlInfo.getVideoDefinitionType),fileKey);
    
    if (self.mediaKeys) {
        NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
        [temDict addEntriesFromDictionary:self.usingUrls];
        [temDict addEntriesFromDictionary:@{fileKey:urls}];
        self.usingUrls = temDict.copy;
    } else {
        self.usingUrls = @{fileKey:urls};
    }
    
    self.mediaKeys = self.mediaKeys ? [self.mediaKeys arrayByAddingObject:fileKey] : @[fileKey];
    NSString *downloadUrl = [TTVideoEngine _ls_downloadUrl:fileKey rawKey:self.videoId urls:urls];
    [TTVideoEngine _ls_startDownload:downloadUrl];
    return YES;
}

- (void)_downloadWithVideoModel:(TTVideoEngineModel *)videoModel {
    TTVideoEngineLog(@"[downloader] download videoModel, videoId = %@, resolution = %@",self.videoId,@(self.resolution));
    if (_resolutionMap && _resolutionMap.count > 0) {
        [videoModel.videoInfo setUpResolutionMap:_resolutionMap];
    }
    
    self.mediaKeys = nil;
    self.usingUrls = nil;
    
    TTVideoEngineResolutionType temTyp = self.resolution;
    if ([[videoModel.videoInfo getValueStr:VALUE_DYNAMIC_TYPE] isEqualToString:@"segment_base"]) {
        TTVideoEngineURLInfo *audioInfo = [videoModel.videoInfo videoInfoForType:&temTyp mediaType:@"audio" autoMode:YES];
        if (audioInfo) {
            if (![self _downloadWithUrlInfo:audioInfo]) {
                return;
            }
            self.currentResolution = temTyp;
        }
        temTyp = self.resolution;
        TTVideoEngineURLInfo *videoInfo = [videoModel.videoInfo videoInfoForType:&temTyp mediaType:@"video" autoMode:YES];
        if (videoInfo) {
            if(![self _downloadWithUrlInfo:videoInfo]){
                return;
            }
            self.currentResolution = temTyp;
        }
    } else {
        TTVideoEngineURLInfo *urlInfo = [videoModel.videoInfo videoInfoForType:&temTyp autoMode:YES];
        if (urlInfo) {
            if(![self _downloadWithUrlInfo:urlInfo]){
                return;
            }
            self.currentResolution = temTyp;
        }
    }
    
    [self.downloader resume:self];
}

- (BOOL)bytevc1Enable {
    return _codecType == TTVideoEngineByteVC1;
}

@end
/// MARK: -

NS_ASSUME_NONNULL_END


