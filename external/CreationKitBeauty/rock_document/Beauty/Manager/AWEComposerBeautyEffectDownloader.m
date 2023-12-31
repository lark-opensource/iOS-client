//
//  AWEComposerBeautyEffectDownloader.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/18.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitBeauty/ACCNetworkReachabilityProtocol.h>

#import <netdb.h>
#import <arpa/inet.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "CKBConfigKeyDefines.h"

static const NSInteger kAWEStudioComposerBeautyEffectDownloadMaxConcurrent = 3;
static const NSInteger kAWEStudioComposerBeautyEffectRetryDownloadMaxTimes = 3;

NSString *const kAWEComposerBeautyEffectUpdateNotification = @"com.composerBeautyEffect.ComposerEffectUpdateNotification";

@interface AWEComposerBeautyEffectDownloader()

// Downloading
@property (nonatomic, assign) NSInteger nextDownloadIndex;
@property (nonatomic, strong) NSArray *allEffects;
@property (nonatomic, strong) NSMutableArray *downloadingEffects;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, assign) NSInteger retryDownloadTimes;
@property (nonatomic, strong) id<ACCNetworkReachabilityProtocol> reachabilityManager;
@end

static AWEComposerBeautyEffectDownloader *sharedDownloader = nil;

@implementation AWEComposerBeautyEffectDownloader

IESAutoInject(ACCBaseServiceProvider(), reachabilityManager, ACCNetworkReachabilityProtocol)

#pragma mark - Singleton

+ (AWEComposerBeautyEffectDownloader *)defaultDownloader
{
    if (!sharedDownloader) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedDownloader = [[AWEComposerBeautyEffectDownloader alloc] init];
        });
    }
    return sharedDownloader;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(kAWEStudioComposerBeautyEffectDownloadMaxConcurrent);
        _downloadQueue = dispatch_queue_create("com.aweme.composerBeautyEffectManager.downloadQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadingEffects = [NSMutableArray array];
        _allEffects = [NSArray array];
        _lock = [NSLock new];
        [self.reachabilityManager addNotificationObserver:self selector:@selector(handleNetworkChanged:) object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.reachabilityManager removeObserver:self];
}

#pragma mark - Public APIs

- (void)downloadEffects:(NSArray *)effects
{
    self.retryDownloadTimes = 0;
    NSMutableArray *allEffects = [self.allEffects mutableCopy];
    for (AWEComposerBeautyEffectWrapper *effect in effects) {
        if (!effect.downloaded && ![allEffects containsObject:effect]) {
            [allEffects acc_addObject:effect];
        }
    }
    self.allEffects = [allEffects copy];
    [self addNextEffectToDownloadQueue];
}

- (BOOL)allEffectsDownloaded
{
    BOOL allDownloaded = YES;
    for (AWEComposerBeautyEffectWrapper *effectWrapper in self.allEffects) {
        if (![effectWrapper downloaded]) {
            allDownloaded = NO;
        }
    }
    return allDownloaded && ACC_isEmptyArray(self.downloadingEffects);
}

- (AWEEffectDownloadStatus)downloadStatusOfEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (effectWrapper.isNone || [effectWrapper downloaded]) {
        return AWEEffectDownloadStatusDownloaded;
    } else if ([self isDownloading:effectWrapper]) {
        return AWEEffectDownloadStatusDownloading;
    } else {
        return AWEEffectDownloadStatusUndownloaded;
    }
}

- (void)addNextEffectToDownloadQueue
{
    NSArray *effects = [self.allEffects copy];
    if (self.nextDownloadIndex >= effects.count) {
        [self checkForUndownloadedEffects];
        return;
    }
    for (NSInteger i = self.nextDownloadIndex; i < effects.count; i++) {
        AWEComposerBeautyEffectWrapper *effectWrapper = effects[i];
        
        /*
         even if the beauty effect resource and relative algorithm models
         had downloaded, call the `downloaded` method will return NO if
         EffectPlatformSDK not finish fetch online model list.
         
         so here we should post notification
        */
        BOOL downloaded = [effectWrapper downloaded];
        if (downloaded) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAWEComposerBeautyEffectUpdateNotification object:effectWrapper];
        } else if (!downloaded && ![self isDownloading:effectWrapper]) {
            if (self.downloadingEffects.count < kAWEStudioComposerBeautyEffectDownloadMaxConcurrent) {
                [self addEffectToDownloadQueue:effectWrapper];
                self.nextDownloadIndex = i + 1;
            } else {
                self.nextDownloadIndex = i;
                return;
            }
        }
    }
    self.nextDownloadIndex = effects.count;
}

- (void)addEffectToDownloadQueue:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if ([effectWrapper downloaded] || [self isDownloading:effectWrapper]) {
        return ;
    }
    IESEffectModel *effectModel = effectWrapper.effect;
    [self.lock lock];
    [self.downloadingEffects acc_addObject:effectWrapper];
    [self.lock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAWEComposerBeautyEffectUpdateNotification object:effectWrapper];
    @weakify(self);
    dispatch_async(self.downloadQueue, ^{
        @strongify(self);
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

        CFTimeInterval singleFilterStartTime = CFAbsoluteTimeGetCurrent();
        [EffectPlatform downloadEffect:effectModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            if (error) {
                acc_dispatch_main_async_safe(^{
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                        [self trackEffect:effectModel withDownloadError:error];
                    }
                });
            } else {
                NSDictionary *extraInfo = @{
                    @"filter_effect_id" : effectModel.effectIdentifier ?: @"",
                    @"filter_name" : effectModel.effectName ?: @"",
                    @"download_urls" : [effectModel.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                    @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk))
                };
                [ACCMonitor() trackService:@"aweme_beauty_platform_download_error"
                                 status:1
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                      @"duration" : @((CFAbsoluteTimeGetCurrent() - singleFilterStartTime) * 1000)
                                  }]];
            }
            dispatch_semaphore_signal(self.semaphore);
            [self.lock lock];
            [self.downloadingEffects removeObject:effectWrapper];
            [self.lock unlock];
            if (self.downloadingEffects.count < kAWEStudioComposerBeautyEffectDownloadMaxConcurrent) {
                [self addNextEffectToDownloadQueue];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kAWEComposerBeautyEffectUpdateNotification object:effectWrapper];
        }];
    });
}


#pragma mark - Network

- (void)checkForUndownloadedEffects
{
    NSMutableArray *undownloadedEffects = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effectWrapper in self.allEffects) {
        if (![effectWrapper downloaded]) {
            [undownloadedEffects acc_addObject:effectWrapper];
        }
    }
    self.allEffects = [undownloadedEffects copy];
    if (!ACC_isEmptyArray(undownloadedEffects) &&
        self.retryDownloadTimes < kAWEStudioComposerBeautyEffectRetryDownloadMaxTimes) {
        
        self.nextDownloadIndex = 0;
        self.retryDownloadTimes += 1;
        [self addNextEffectToDownloadQueue];
    }
}

- (void)handleNetworkChanged:(NSNotification *)notification
{
    if (self.reachabilityManager.isReachable) {
        [self addNextEffectToDownloadQueue];
    }
}

- (NSString *)getIPFromURLList:(NSArray *)urlArray
{
    NSMutableString *ipString = @"".mutableCopy;
    
    for (NSString *urlString in urlArray) {
        NSURL *url = [NSURL URLWithString:urlString];
        
        if (url.host) {
            NSArray *ipArray = [self getIPArrayFromHost:url.host];
            [ipString appendFormat:@"%@:%@;",url.host,[ipArray componentsJoinedByString:@","]?:@""];
        }
    }
    
    return ipString;
}

- (NSArray *)getIPArrayFromHost:(NSString *)host
{
    NSString *portStr = [NSString stringWithFormat:@"%hu", (short)80];
    struct addrinfo hints, *res;
    void *addr;
    char ipstr[INET6_ADDRSTRLEN];
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res);
    if (!gai_error) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        while (res) {
            addr = NULL;
            if (res->ai_family == AF_INET) {
                struct sockaddr_in *ipv4 = (struct sockaddr_in *)res->ai_addr;
                addr = &(ipv4->sin_addr);
            } else if (res->ai_family == AF_INET6) {
                struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)res->ai_addr;
                addr = &(ipv6->sin6_addr);
            }
            if (addr) {
                const char *ip = inet_ntop(res->ai_family, addr, ipstr, sizeof(ipstr));
                [arr acc_addObject:[NSString stringWithUTF8String:ip]];
            }
            res = res->ai_next;
        }
        freeaddrinfo(res);
        return arr;
    } else {
        return nil;
    }
}

#pragma mark - Private

- (BOOL)isDownloading:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self.lock lock];
    BOOL result = [[self.downloadingEffects copy] containsObject:effectWrapper];
    [self.lock unlock];
    return result;
}

- (void)trackEffect:(IESEffectModel *)effectModel withDownloadError:(NSError *)error
{
    __block NSDictionary *extraInfo = @{
        @"filter_effect_id" : effectModel.effectIdentifier ?: @"",
        @"filter_name" : effectModel.effectName ?: @"",
        @"download_urls" : [effectModel.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
        @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk))
    };
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *ipString = [self getIPFromURLList:effectModel.fileDownloadURLs];
        id networkResponse = error.userInfo[IESEffectNetworkResponse];
        if ([networkResponse isKindOfClass:[TTHttpResponse class]]) {
            TTHttpResponse *ttResponse = (TTHttpResponse *)networkResponse;
            extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                @"httpStatus" : @(ttResponse.statusCode),
                @"httpHeaderFields":
                    ttResponse.allHeaderFields.description ?: @""
            }];
            if ([ttResponse isKindOfClass:[TTHttpResponseChromium class]]) {
                TTHttpResponseChromium *chromiumResponse = (TTHttpResponseChromium *)ttResponse;
                NSString *requestLog = chromiumResponse.requestLog;
                extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                    @"ttRequestLog" : requestLog ?: @""}];
            }
        } else if ([networkResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)networkResponse;
            extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                @"httpStatus" : @(httpResponse.statusCode),
                @"httpHeaderFields":
                    httpResponse.allHeaderFields.description ?: @""
            }];
        }
        [ACCMonitor() trackService:@"aweme_beauty_platform_download_error"
                         status:0
                          extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                              @"errorCode" : @(error.code),
                              @"errorDesc" : error.localizedDescription ?: @"",
                              @"errorDomain": error.domain ?: @"",
                              @"ip":ipString?:@"",
                          }]];
    });
}

@end
