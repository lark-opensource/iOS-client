//
//  AWEColorFilterDataManager.m
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
// 

#import "AWEColorFilterDataManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <CreationKitArch/AWEStudioMeasureManager.h>
#import "CKConfigKeysDefines.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLangRegionLisener.h>
#import <CreationKitInfra/ACCRTLProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#define ALP_IGNORE

NSString *const kAWEStudioColorFilterUpdateNotification = @"kAWEStudioColorFilterUpdateNotification";
NSString *const kAWEStudioColorFilterListUpdateNotification = @"kAWEStudioColorFilterListUpdateNotification";
NSInteger const kAWEStudioColorFilterDownloadMaxConcurrent = 3;

@interface AWEColorFilterDataManager ()

@property (nonatomic, strong) NSString *frontFilterId;
@property (nonatomic, strong) NSString *rearFilterId;
@property (nonatomic, strong) NSMutableSet<NSString *> *tempURLSet; // Temporary storage, clear after sending notification

@property (nonatomic, strong, readwrite) IESEffectModel *frontCameraFilter;
@property (nonatomic, strong, readwrite) IESEffectModel *rearCameraFilter;
@property (nonatomic, strong, readwrite) IESEffectModel *normalFilter;

@property (nonatomic, copy, readwrite) NSString *panel;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, strong) NSMutableArray *downloadingEffects;
@property (nonatomic, assign) NSInteger nextDownloadIndex;
@property (nonatomic, assign, readwrite) BOOL isFetching;
@property (nonatomic, assign, readwrite) BOOL enableComposerFilter;
@property (nonatomic, strong) NSArray<IESEffectModel *> *allEffects;
@property (nonatomic, strong) NSMutableDictionary *colorFilterConfigurationHelperDic;

@property (nonatomic, copy, readwrite, nullable) NSArray<IESEffectModel *> * (^buildInFilterArrayBlock)(void);

@end

@implementation AWEColorFilterDataManager

+ (instancetype)defaultManager
{
    static dispatch_once_t onceToken;
    static AWEColorFilterDataManager *dataManager = nil;
    dispatch_once(&onceToken, ^{
        dataManager = [[AWEColorFilterDataManager alloc] init];
    });
    return dataManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _enableComposerFilter = ACCConfigBool(kConfigBool_enable_composer_filter);
        _panel = [self getDefaultPanelWithEnableComposer:_enableComposerFilter];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLanguageChangedRefreshFilterResource:) name:ACC_LANGUAGE_CHANGE_NOTIFICATION object:nil];
        _semaphore = dispatch_semaphore_create(kAWEStudioColorFilterDownloadMaxConcurrent);
        char *downLoadQueueIdentifier = self.filterPanelType == ACCFilterPanelTypeDefault ? "com.aweme.effectFilterDataManager.downloadQueue" : "com.aweme.effectFilterDataManager.downloadQueue-specialFilter";
        _downloadQueue = dispatch_queue_create(downLoadQueueIdentifier, DISPATCH_QUEUE_CONCURRENT);
        _downloadingEffects = [NSMutableArray array];
        _allEffects = [NSArray array];
        
        [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    }
    return self;
}

- (instancetype)initWithEnableComposerFilter:(BOOL)enableComposerFilter
{
    if (self = [self init]) {
        _enableComposerFilter = enableComposerFilter;
        _panel = [self getDefaultPanelWithEnableComposer:enableComposerFilter];
    }
    return self;
}

- (NSString *)getDefaultPanelWithEnableComposer:(BOOL)enableComposerFilter
{
    NSInteger panelIndex = ACCConfigInt(kConfigInt_color_filter_panel);
    NSString *colorFilterPanelName = nil;
    if (panelIndex == 1) {
        colorFilterPanelName = enableComposerFilter ? @"filtercomposer" : @"colorfilternew";
    } else if (panelIndex == 2) {
        colorFilterPanelName = enableComposerFilter ? @"filtercomposerexperiment" : @"colorfilterexperiment";
    } else if (panelIndex > 100) {
        colorFilterPanelName = @(panelIndex).stringValue;
    }
    return colorFilterPanelName;
}

- (NSString *)panel
{
    if (!_panel) {
        return _enableComposerFilter ? @"filtercomposer" : @"colorfilternew";
    }
    return _panel;
}

- (void)updatePanelName:(NSString *)panelName
{
    _panel = panelName;
}

- (void)updateEffectFilters
{
    [self updateEffectFiltersForce:NO];
}

- (void)updateEffectFiltersForce:(BOOL)force
{
    if (self.isFetching) {
        return;
    }
    self.isFetching = YES;
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:self.panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        void(^downloadResponseEffectBlock)(IESEffectPlatformResponseModel *) = ^(IESEffectPlatformResponseModel *response){
            self.nextDownloadIndex = 0;
            [self updateAllEffectsWithResponse:response reset:YES];
            [self addNextEffectToDownloadQueue];
        };
        
        self.isFetching = NO;
        CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panel];
        if (needUpdate || !cachedResponse || force) {
            [EffectPlatform downloadEffectListWithPanel:self.panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                if (!error) {
                    [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:40 extra:@{
                                                                                                                                          @"panel" : self.panel ?: @"",
                                                                                                                                          @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                                                                          @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                                                                                          @"needUpdate" : @(YES)
                                                                                                                                          }];
                    self.rearFilterId = response.defaultRearFilterID;
                    self.frontFilterId = response.defaultFrontFilterID;
                    ACCBLOCK_INVOKE(downloadResponseEffectBlock, response);
                    // After the cache is saved, a notification is issued to refresh the data
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioColorFilterListUpdateNotification object:@(YES)];
                    });
                } else {
                    [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:41 extra:@{
                                                                                                                                          @"panel" : self.panel ?: @"",
                                                                                                                                          @"errorDesc":error.description ?: @"",
                                                                                                                                          @"errorCode":@(error.code),
                                                                                                                                          @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                                                                                          @"needUpdate" : @(YES)
                                                                                                                                          }];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioColorFilterListUpdateNotification object:@(NO)];
                }
            }];
        } else {
            self.rearFilterId = cachedResponse.defaultRearFilterID;
            self.frontFilterId = cachedResponse.defaultFrontFilterID;
            [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:40 extra:@{
                                                                                                                                  @"panel" : self.panel ?: @"",
                                                                                                                                  @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                                                                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                                                                                  @"needUpdate" : @(NO)
                                                                                                                                  }];
            ACCBLOCK_INVOKE(downloadResponseEffectBlock, cachedResponse);
        }
    }];
}

- (NSArray<IESEffectModel *> *)availableEffects
{
    // Flattedaggregatedeffects is a downloaded special effect. If the number is less than 5, use the default filter
    NSArray<IESEffectModel *> *effectArray = [self flattenedAggregatedEffects];
    if (effectArray.count > 0) {
        return effectArray;
    } else {
        return [self builtinEffects];
    }
}

- (NSArray<IESEffectModel *> *)builtinEffects
{
    if (self.buildInFilterArrayBlock) {
        return self.buildInFilterArrayBlock();
    }
    return [IESEffectModel acc_builtinEffects];
}

- (void)fetchEffectListStateCompletion:(EffectPlatformFetchListCompletionBlock)completion
{
    [EffectPlatform fetchEffectListStateWithPanel:self.panel completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
        if (completion) {
            completion(error, response);
        }
        self.nextDownloadIndex = 0;
        [self updateAllEffectsWithResponse:response reset:NO];
        [self addNextEffectToDownloadQueue];
    }];
}

- (void)updateEffectListStateWithCheckArray:(NSArray *)checkArray uncheckArray:(NSArray *)uncheckArray
{
    [EffectPlatform updateEffectListStateWithPanel:self.panel checkArray:checkArray uncheckArray:uncheckArray completion:^(NSError * _Nonnull error, BOOL success) {
        if (success) {
            // Status synchronization succeeded, forced to pull the latest filter list
            [self updateEffectFiltersForce:YES];
        }
    }];
}

- (NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *)aggregatedEffects {
    IESEffectPlatformResponseModel *response = [EffectPlatform cachedEffectsOfPanel:self.panel];
    NSMutableArray *aggregatedEffects = [NSMutableArray array];
    NSInteger downloadedCount = 0;
    if (response.categories.count > 0) {
        for (IESCategoryModel *category in response.categories) {
            NSMutableArray *downloadedEffects = [NSMutableArray array];
            for (IESEffectModel *model in category.effects) {
                if (model.downloaded) {
                    [downloadedEffects addObject:model];
                    downloadedCount += 1;
                }
            }
            if (downloadedEffects.count > 0) {
                NSDictionary *categoryDict = @{ category : [downloadedEffects copy] };
                [aggregatedEffects addObject:categoryDict];
            }
        }
    } else {
        // A dummy category
        IESCategoryModel *category = [[IESCategoryModel alloc] init];
        [aggregatedEffects addObjectsFromArray:@[@{ category : [self builtinEffects] }]];
    }
    return aggregatedEffects;
}

- (NSArray<NSDictionary<IESCategoryModel *, NSArray<IESEffectModel *> *> *> *)allAggregatedEffects {
    IESEffectPlatformResponseModel *response = [EffectPlatform cachedEffectsOfPanel:self.panel];
    NSMutableArray *aggregatedEffects = [NSMutableArray array];
    if (response.categories.count > 0) {
        for (IESCategoryModel *category in response.categories) {
            NSDictionary *categoryDict = @{ category : [category.effects copy] };
            [aggregatedEffects addObject:categoryDict];
        }
    } else {
        IESCategoryModel *category = [[IESCategoryModel alloc] init];
        [aggregatedEffects addObjectsFromArray:@[@{ category : [self builtinEffects] }]];
    }
    return aggregatedEffects;
}

- (NSArray<IESEffectModel *> *)flattenedAggregatedEffects {
    NSMutableArray<IESEffectModel *> *tmpArray = [NSMutableArray array];
    for (NSDictionary *dict in self.aggregatedEffects) {
        NSArray *currentValues = (NSArray<IESEffectModel *> *)dict.allValues.firstObject;
        if (currentValues) {
            [tmpArray addObjectsFromArray:currentValues];
        }
    }
    return [tmpArray copy];
}

- (IESEffectModel *)effectWithID:(NSString *)effectId
{
    if (effectId.length <= 0) {
        return nil;
    }
    
    NSArray *effectArray = [self availableEffects].copy;
    
    for (IESEffectModel *effect in effectArray) {
        if ([effect.resourceId isEqualToString:effectId] ||
            [effect.effectIdentifier isEqual:effectId]) {
            return effect;
        }
    }
    return nil;
}

+ (IESEffectModel *)effectWithID:(NSString *)effectId
{
    return [[AWEColorFilterDataManager defaultManager] effectWithID:effectId];
}

+ (void)loadEffectWithID:(NSString *)effectId completion:(void (^)(IESEffectModel *))completion
{
    if (effectId.length <= 0) {
        ACCBLOCK_INVOKE(completion, nil);
    }
    
    IESEffectModel *effect = [self effectWithID:effectId];
    if (!effect) {
        [EffectPlatform downloadEffectListWithEffectIDS:@[effectId] completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            if (error || effects.count == 0) {
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion, nil);
                });
                return;
            }
            
            IESEffectModel *validEffect = effects.firstObject;
            [EffectPlatform downloadEffect:validEffect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                acc_dispatch_main_async_safe(^{
                    if (error || effects.count == 0 || !validEffect.downloaded) {
                        ACCBLOCK_INVOKE(completion, nil);
#if DEBUG || INHOUSE_TARGET
                        if (error) {
                            [ACCToast() show:error.description];
                        }
#endif
                        return;
                    }

                    ACCBLOCK_INVOKE(completion, validEffect);
                });
            }];
        }];
    } else {
        ACCBLOCK_INVOKE(completion, effect);
    }
}

- (IESEffectModel *)frontCameraFilter
{
    return [self effectWithID:self.frontFilterId];
}

- (IESEffectModel *)rearCameraFilter
{
    return [self effectWithID:self.rearFilterId];
}

- (IESEffectModel *)normalFilter
{
    IESEffectModel *normalFilter;
    for (IESEffectModel *filter in self.availableEffects) {
        if (filter.isNormalFilter) {
            normalFilter = filter;
            break;
        }
    }
    return normalFilter;
}

+ (IESEffectModel *)prevFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray
{
    if (filterArray.count == 0) {
        return nil;
    }
    
    NSUInteger currentFilterIndex = [filterArray indexOfObject:filter];
    if (currentFilterIndex == NSNotFound) {
        currentFilterIndex = 0;
    }
    NSInteger step = [ACCRTL() isRTL] ? 1 : -1;
    NSUInteger prevFilterIndex = (currentFilterIndex + step + filterArray.count) % filterArray.count;
    return filterArray[prevFilterIndex];
}

+ (IESEffectModel *)nextFilterOfFilter:(IESEffectModel *)filter filterArray:(NSArray *)filterArray
{
    if (filterArray.count == 0) {
        return nil;
    }
    
    NSUInteger currentFilterIndex = [filterArray indexOfObject:filter];
    if (currentFilterIndex == NSNotFound) {
        currentFilterIndex = 0;
    }
    NSInteger step = [ACCRTL() isRTL] ? -1 : 1;
    NSUInteger nextFilterIndex = (currentFilterIndex + step + filterArray.count) % filterArray.count;
    return filterArray[nextFilterIndex];
}

- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect
{
    if (effect.downloaded || effect.isBuildin) {
        return AWEEffectDownloadStatusDownloaded;
    } else if ([self.downloadingEffects containsObject:effect]){
        return AWEEffectDownloadStatusDownloading;
    } else {
        return AWEEffectDownloadStatusUndownloaded;
    }
}

- (void)updateAllEffectsWithResponse:(IESEffectPlatformResponseModel *)response reset:(BOOL)reset {
    NSMutableArray *candidates = [NSMutableArray array];
    if (!reset) {
        [candidates addObjectsFromArray:self.allEffects];
    }
    for (IESCategoryModel *category in response.categories) {
        for (IESEffectModel *effect in category.effects) {
            if (![candidates containsObject:effect]) {
                [candidates addObject:effect];
            }
        }
    }
    self.allEffects = [candidates copy];
}

- (void)addNextEffectToDownloadQueue
{
    NSArray *effects = self.allEffects;
    if (self.nextDownloadIndex >= effects.count) {
        return;
    }
    for (NSInteger i = self.nextDownloadIndex; i < effects.count; i++) {
        IESEffectModel *effect = effects[i];
        if (!effect.downloaded && ![self.downloadingEffects containsObject:effect]) {
            if (self.downloadingEffects.count < kAWEStudioColorFilterDownloadMaxConcurrent) {
                [self addEffectToDownloadQueue:effect];
                self.nextDownloadIndex = i + 1;
            } else {
                self.nextDownloadIndex = i;
                return;
            }
        }
    }
    self.nextDownloadIndex = effects.count;
}

- (void)addEffectToDownloadQueue:(IESEffectModel *)effectModel
{
    [self.downloadingEffects addObject:effectModel];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioColorFilterUpdateNotification object:effectModel];
    @weakify(self);
    dispatch_async(self.downloadQueue, ^{
        @strongify(self);
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
        CFTimeInterval singleFilterStartTime = CFAbsoluteTimeGetCurrent();
        [EffectPlatform downloadEffect:effectModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            __block NSDictionary *extraInfo = @{
                                        @"filter_effect_id" : effectModel.effectIdentifier ?: @"",
                                        @"filter_name" : effectModel.effectName ?: @"",
                                        @"download_urls" : [effectModel.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                                        @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk))
                                        };
            if (error) {
                acc_dispatch_main_async_safe(^{
                    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
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
                            [ACCMonitor() trackService:@"aweme_filter_platform_download_error"
                                             status:0
                                              extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                                             @"errorCode" : @(error.code),
                                                                                                             @"errorDesc" : error.localizedDescription ?: @"",
                                                                                                             @"errorDomain": error.domain ?: @"",
                                                                                                             @"ip":ipString?:@"",
                                                                                                             @"panel": self.panel ?: @"",
                                                                                                             }]];
                        });
                    }
                });
            } else {
                [ACCMonitor() trackService:@"aweme_filter_platform_download_error"
                                 status:1
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                                 @"duration" : @((CFAbsoluteTimeGetCurrent() - singleFilterStartTime) * 1000),
                                                                                                 @"panel": self.panel ?: @"",
                                                                                                 }]];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioColorFilterUpdateNotification object:effectModel];
            dispatch_semaphore_signal(self.semaphore);
            [self.downloadingEffects removeObject:effectModel];
            if (self.downloadingEffects.count < kAWEStudioColorFilterDownloadMaxConcurrent) {
                [self addNextEffectToDownloadQueue];
            }
        }];
    });
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
    struct addrinfo hints, *res, *p;
    void *addr;
    char ipstr[INET6_ADDRSTRLEN];
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res);
    if (!gai_error) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        p = res;
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
                [arr addObject:[NSString stringWithUTF8String:ip]];
            }
            res = res->ai_next;
        }
        freeaddrinfo(p);
        return arr;
    } else {
        return nil;
    }
}

#pragma mark - Notitifation

- (void)handleLanguageChangedRefreshFilterResource:(NSNotification *)info {
    // Clear the cache and pull the filter resource of the corresponding language | country again
    [EffectPlatform clearCache];
    [self updateEffectFilters];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AWEColorFilterConfigurationHelper

- (AWEColorFilterConfigurationHelper *)colorFilterConfigurationHelperWithType:(AWEColorFilterConfigurationType)type {
    if (!_colorFilterConfigurationHelperDic) {
        _colorFilterConfigurationHelperDic = [@{} mutableCopy];
    }
    AWEColorFilterConfigurationHelper *helper = [_colorFilterConfigurationHelperDic acc_objectForKey:@(type) ofClass:[AWEColorFilterConfigurationHelper class]];
    if (!helper) {
        helper = [[AWEColorFilterConfigurationHelper alloc] initWithBeautyConfiguration:type];
        [_colorFilterConfigurationHelperDic setObject:helper forKey:@(type)];
    }
    return helper;
}

#pragma mark - Inject build in filter datasource

- (void)injectBuildInFilterArrayBlock:(NSArray<IESEffectModel *> *(^)(void))block
{
    self.buildInFilterArrayBlock = block;
}

@end
