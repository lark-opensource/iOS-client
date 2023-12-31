//
//  TTVideoEngineMDLFetcher.m
//  ABRInterface
//
//  Created by kun on 2021/1/19.
//

#import "TTVideoEngineMDLFetcher.h"
#import "TTVideoEngineFetcherMaker.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineModelCache.h"
#import <TTPlayerSDK/ByteCrypto.h>

@implementation TTVideoEngineMDLFetcher

- (instancetype)initWithMDLFetcherDelegate:(id)delegate {
    self = [super init];
    if (self) {
        _mdlFetcherDelegate = delegate;
    }
    return self;
}

- (void)close {
    TTVideoEngineLog(@"mdlFetch close");
    if (self.infoFetcher) {
        [self.infoFetcher cancel];
        self.infoFetcher = nil;
    }
    
    self.mdlFetcherDelegate = nil;
}

- (nonnull NSArray<NSString *> *)getURLs {
    if (_urls && _urls.count > 0) {
        TTVideoEngineLog(@"mdlFetch getURLs length %lu",(unsigned long)_urls.count);
    } else {
        TTVideoEngineLog(@"mdlFetch getURLs urls is empty");
    }
   
    return _urls;
}

- (NSInteger)start:(nonnull NSString *)rawKey
           fileKey:(nonnull NSString *)fileKey
            oldUrl:(nonnull NSString *)oldUrl
          listener:(nonnull id<AVMDLiOSURLFetcherListener>)listener {
    TTVideoEngineLog(@"mdlFetch start rawKey %@, fileKey %@, oldUrl %@, listener %d"
                     , rawKey, fileKey, oldUrl, listener != nil);
    self.listener = listener;
    self.videoID = rawKey;
    self.fileHash = fileKey;
    self.oldUrl = oldUrl;
    
    id<TTVideoEngineMDLFetcherDelegate> delegate = [self getMDLFetcherDelegate];
    if (!delegate) {
        TTVideoEngineLog(@"start MDLFetcherListener is null return MDL_GET_URLS");
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry code:TTVideoEngineErrorMDLFetcherListenerEmpty userInfo:@{@"description":@"MDLFetcherListener is empty"}] callbackToMDL:false];
        return MDL_GET_URLS;
    }
    [delegate onMdlRetryStart:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry code:-499897 userInfo:nil]];
    
    NSString *fallbackApi = [delegate getFallbackApi];
    if (isEmptyStringForVideoPlayer(fallbackApi)) {
        TTVideoEngineLog(@"start fallbackApi is empty return MDL_GET_URLS");
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry code:TTVideoEngineErrorFallbackApiEmpty userInfo:@{@"description":@"fallbackApi is empty"}] callbackToMDL:false];
        return MDL_GET_URLS;
    }
    
    NSArray<NSString *> *urls = [self getUrlsFromCache:rawKey fileHash:fileKey oldUrl:oldUrl];
    if (urls && urls.count > 0) {
        self.urls = urls;
        TTVideoEngineLog(@"start return MDL_GET_URLS");
        [self onCompletion:self.videomodel isNewModel:false];
        return MDL_GET_URLS;
    }
    
    //need fetch videomodel
    NSDictionary *params = @{@"method": [NSString stringWithFormat:@"%d",TTVideo_getCryptoMethod()],
                             @"useFallbackApi": @"enable"};
    self.infoFetcher = [[TTVideoEngineInfoFetcher alloc] init];
    self.infoFetcher.delegate = (id<TTVideoInfoFetcherDelegate>)self;
    // fallback PLAY_API_VERSION_0 only
    self.infoFetcher.apiversion = 0;
    self.infoFetcher.cacheModelEnable = true;
    self.infoFetcher.useEphemeralSession = true;
    fallbackApi = TTVideoEngineBuildHttpsApi(fallbackApi);
    [self.infoFetcher fetchInfoWithAPI:fallbackApi
                            parameters:params
                                  auth:nil
                                   vid:rawKey
                                   key:nil];
    TTVideoEngineLog(@"start return CALLBACK_URLS_TO_MDL");
    return CALLBACK_URLS_TO_MDL;
}

- (NSArray<NSString *> *)getUrlsFromCache:(NSString *)vid
                                 fileHash:(NSString *)fileHash
                                   oldUrl:(NSString *)oldUrl {
    TTVideoEngineModelCache *videoModelCache = TTVideoEngineModelCache.shareCache;
    __block id<NSCoding> obj = nil;
    @weakify(self)
    [videoModelCache getItemFromDiskForKey:vid withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        @strongify(self)
        obj = object;
    }];
    
    if (!obj) {
        TTVideoEngineLog(@"getURLsFromCache videomodel is null");
        return nil;
    }
    
    TTVideoEngineModel *model = (TTVideoEngineModel *) obj;
    if ([model hasExpired]) {
        TTVideoEngineLog(@"getURLsFromCache videomodel is expired");
        return nil;
    }
    
    self.videomodel = model;
    NSArray<NSString *> *temUrls = [self getUrlsFromVideoModel:model byFileHash:fileHash];
    if (!temUrls || temUrls.count <= 0) {
        TTVideoEngineLog(@"getURLsFromCache temUrls is null");
        return nil;
    }
    
    if (![self isNewUrlsValid:temUrls withOldUrl:oldUrl]) {
        [videoModelCache removeItemFromDiskForKey:vid];
        TTVideoEngineLog(@"getURLsFromCache urls is invalid");
        return nil;
    }
    
    TTVideoEngineLog(@"getURLsFromCache urls: %@", temUrls);
    return temUrls;
}

- (NSArray<NSString *> *)getUrlsFromVideoModel:(TTVideoEngineModel *)videoModel
                                    byFileHash:(NSString *) fileHash {
    if (!fileHash) {
        return nil;
    }
    
    if (!videoModel || !videoModel.videoInfo) {
        return nil;
    }
    
    NSMutableArray<TTVideoEngineURLInfo *> * urlInfoArray= [videoModel.videoInfo getValueArray:VALUE_VIDEO_LIST];
    if (!urlInfoArray || urlInfoArray.count == 0) {
        return nil;
    }
    
    for (TTVideoEngineURLInfo *urlInfo in urlInfoArray) {
        if ([fileHash isEqualToString: urlInfo.fileHash]) {
            NSMutableArray *urls = [[NSMutableArray alloc] init];
            if (urlInfo.mainURLStr) {
                [urls addObject:urlInfo.mainURLStr];
            }
            if (urlInfo.backupURL1) {
                [urls addObject:urlInfo.backupURL1];
            }
            if (urlInfo.backupURL2) {
                [urls addObject:urlInfo.backupURL2];
            }
            if (urlInfo.backupURL3) {
                [urls addObject:urlInfo.backupURL3];
            }
            
            return urls;
        }
    }
    
    return nil;
}

- (BOOL)isNewUrlsValid:(NSArray<NSString*>*) newUrls withOldUrl:(NSString*)oldUrl {
    if (!newUrls || newUrls.count <= 0) {
        return NO;
    }
    
    if (!oldUrl || !oldUrl.length) {
        return YES;
    }
    
    for (id url in newUrls) {
        if ([oldUrl isEqualToString:url]) {
            TTVideoEngineLog(@"new urls is invalid");
            return NO;
        }
    }
    return YES;
}

- (id<TTVideoEngineMDLFetcherDelegate>)getMDLFetcherDelegate {
    if (!self.mdlFetcherDelegate) {
        TTVideoEngineLog(@"getMDLFetcherDelegate is null");
        return nil;
    }
    return self.mdlFetcherDelegate;
}

- (void)onError:(NSError *)error callbackToMDL:(BOOL)callbackToMDL {
    TTVideoEngineLog(@"MDLFetcher onError,code:%ld, %@, %@, %@", error.code, error.domain, error.userInfo, error.description);
    if (callbackToMDL && self.listener) {
        [self.listener onCompletion:error.code rawkey:self.videoID fileKey:self.fileHash newURLs:nil];
    }
    id<TTVideoEngineMDLFetcherDelegate> delegate = [self getMDLFetcherDelegate];
    if (delegate) {
        [delegate onMdlRetryEnd];
        [delegate onError:error fileHash:self.fileHash];
    }
    [self close];
}

- (void)onCompletion:(TTVideoEngineModel *)model isNewModel:(BOOL)isNewModel {
    TTVideoEngineLog(@"MDLFetcher onCompletion, isNewModel:%d", isNewModel);
    id<TTVideoEngineMDLFetcherDelegate> delegate = [self getMDLFetcherDelegate];
    if (delegate) {
        [delegate onMdlRetryEnd];
        [delegate onCompletion:model newModel:isNewModel fileHash:self.fileHash];
    }
    [self close];
}

// MARK: - TTVideoInfoFetcherDelegate
- (void)infoFetcherDidFinish:(NSInteger)status {
    TTVideoEngineLog(@"MDLFetcher infoFetcherDidFinish status:%ld", status);
    [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry
                                      code:TTVideoEngineErrorFetchStatusException
                                  userInfo:@{@"internalCode":@(status),
                                             @"description":@"onStatusException"
                                  }]
    callbackToMDL:true];
}

- (void)infoFetcherDidFinish:(TTVideoEngineModel *)videoModel error:(NSError *)error {
    TTVideoEngineLog(@"mdlFetch infoFetcherDidFinish");
    
    if (error) {
        [self onError:error callbackToMDL:true];
        return;
    }
    
    if (!videoModel) {
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry
                                          code:TTVideoEngineErrorResultEmpty
                                      userInfo:@{@"description":@"fetch empty"}]
        callbackToMDL:true];
        return;
    }
    
    self.urls = [self getUrlsFromVideoModel:videoModel
                                 byFileHash:self.fileHash];
    TTVideoEngineLog(@"mdlFetch callback urls %@", self.urls);
    if (!self.urls || self.urls.count == 0) {
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry
                                          code:TTVideoEngineErrorFileHashInvalid
                                      userInfo:@{@"description":@"file hash invalid"}]
        callbackToMDL:true];
        return;
    }
    
    BOOL valid = [self isNewUrlsValid:self.urls withOldUrl:self.oldUrl];
    
    if (valid) {
        if (self.listener) {
            [self.listener onCompletion: MDLFetchResultSuccess
                                 rawkey:self.videoID
                                fileKey:self.fileHash
                                newURLs:self.urls];
        }
        [self onCompletion:videoModel isNewModel:true];
    } else {
        [self onError:[NSError errorWithDomain:kTTVideoErrorDomainMDLRetry
                                          code:TTVideoEngineErrorResultExpired
                                      userInfo:@{@"description":@"fetch videoModel is expired"}]
        callbackToMDL:true];
    }
   
}

- (void)infoFetcherShouldRetry:(NSError *)error {
    if (![self getMDLFetcherDelegate]) {
        return;
    }
    [[self getMDLFetcherDelegate] onRetry:error];
}

- (void)infoFetcherDidCancel {
    if (![self getMDLFetcherDelegate]) {
        return;
    }
    [[self getMDLFetcherDelegate] onMdlRetryEnd];
    [[self getMDLFetcherDelegate] onLog:@"fetcher is cancelled"];
}

- (void)infoFetcherFinishWithDNSError:(NSError *)error {
    [self onError:error callbackToMDL:true];
}

@end
