//
//  AWEEffectFilterDataManager.m
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEEffectFilterDataManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import "CKConfigKeysDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitArch/AWEEffectPlatformManageable.h>

static NSString *const kAWEEffectFilterPanelKey = @"editingeffect";
static NSInteger const kAWEEffectFilterDownloadMaxConcurrent = 3;

@interface AWEEffectFilterDataManager ()

// Query the effect cache according to the effect ID
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESEffectModel *> *effectIdAndEffectCache;
@property (nonatomic, strong) NSRecursiveLock *effectIdAndEffectCacheLock;

// Query the cache of the effect according to the effect name
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESEffectModel *> *effectNameAndEffectCache;
@property (nonatomic, strong) NSRecursiveLock *effectNameAndEffectCacheLock;

@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, strong) NSMutableArray *downloadingEffects;
@property (nonatomic, assign) NSInteger nextDownloadIndex;
@property (nonatomic, assign, readwrite) BOOL isFetching;
@property (nonatomic, strong) IESEffectPlatformResponseModel *p_effectPlatformModelResponseModel;
@property (nonatomic, strong) NSLock *lock;
@end

@implementation AWEEffectFilterDataManager

+ (instancetype)defaultManager
{
    static id manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _effectIdAndEffectCache = [[NSMutableDictionary alloc] init];
        _effectIdAndEffectCacheLock = [[NSRecursiveLock alloc] init];
        
        _effectNameAndEffectCache = [[NSMutableDictionary alloc] init];
        _effectNameAndEffectCacheLock = [[NSRecursiveLock alloc] init];
        
        _semaphore = dispatch_semaphore_create(kAWEEffectFilterDownloadMaxConcurrent);
        _downloadQueue = dispatch_queue_create("com.aweme.effectFilterDataManager.downloadQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadingEffects = [NSMutableArray array];
        _lock = [NSLock new];
        
        [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
    }
    return self;
}

- (void)updateEffectFilters {
    if (self.isFetching) {
        return;
    }
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *panel = kAWEEffectFilterPanelKey;
    self.isFetching = YES;
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        // Download the block for the effect model
        void (^downloadResponseEffectBlock)(IESEffectPlatformResponseModel *) = ^(IESEffectPlatformResponseModel *response){
            self.nextDownloadIndex = 0;
            [self addNextEffectToDownloadQueue];
        };
        
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panel];
        if (needUpdate || !cachedResponse) {
            [EffectPlatform downloadEffectListWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                if (!error && response.effects.count > 0) {
                    
                    // Clear the cache after updating the effect list
                    [self.effectIdAndEffectCacheLock lock];
                    [self.effectIdAndEffectCache removeAllObjects];
                    [self.effectIdAndEffectCacheLock unlock];
                    
                    [self.effectNameAndEffectCacheLock lock];
                    [self.effectNameAndEffectCache removeAllObjects];
                    [self.effectNameAndEffectCacheLock unlock];
                    
                    [ACCMonitor() trackService:@"aweme_effect_list_error"
                                             status:10
                                              extra:@{
                                                  @"panel" : panel ?: @"",
                                                  @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                  @"needUpdate" : @(YES)
                                              }];
                    ACCBLOCK_INVOKE(downloadResponseEffectBlock, response);
                    self.p_effectPlatformModelResponseModel = response;
                    [[NSNotificationCenter defaultCenter] postNotificationName:AWEEffectFilterDataManagerListUpdateNotification object:@(YES)];
                } else {
                    [ACCMonitor() trackService:@"aweme_effect_list_error"
                                             status:11
                                              extra:@{
                                                  @"panel" : panel ?: @"",
                                                  @"errorDesc":error.description ?: @"",
                                                  @"errorCode":@(error.code),
                                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                  @"needUpdate" : @(YES)
                                              }];
                    [[NSNotificationCenter defaultCenter] postNotificationName:AWEEffectFilterDataManagerListUpdateNotification object:@(NO)];
                }
                self.isFetching = NO;
                
                NSInteger duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                NSInteger success = !error && response.effects.count > 0;
                NSMutableDictionary *params = @{@"api_type":@"edit_effect_list",
                                                @"duration":@(duration),
                                                @"status":@(success?0:1),
                                                @"error_domain":error.domain?:@"",
                                                @"error_code":@(error.code)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_api" params:params.copy needStagingFlag:NO];
                // saf test
                NSString *plistChannel = ACCDynamicCast([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"], NSString);
                if ([plistChannel hasPrefix:@"SafTest-Tool"]) {
                    NSMutableDictionary *metricExtra = @{}.mutableCopy;
                    UInt64 end_time = (UInt64)([[NSDate date] timeIntervalSince1970] * 1000);
                    UInt64 start_time = end_time - (UInt64)(duration);
                    [metricExtra addEntriesFromDictionary:@{@"metric_name": @"duration", @"start_time": @(start_time), @"end_time": @(end_time)}];
                    params[@"metric_extra"] = @[metricExtra];
                    [ACCTracker() trackEvent:@"tool_performance_edit_effect_list_saf" params:params.copy needStagingFlag:NO];
                }
            }];
        } else {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                                     status:10
                                      extra:@{
                                          @"panel" : panel ?: @"",
                                          @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                          @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                          @"needUpdate" : @(NO)
                                      }];
            ACCBLOCK_INVOKE(downloadResponseEffectBlock, cachedResponse);
            self.isFetching = NO;
        }
    }];
}

- (NSArray<IESEffectModel *> *)availableEffects
{
    NSMutableArray *availableEffects = [[NSMutableArray alloc] init];
    NSArray *downloadedEffects = [EffectPlatform cachedEffectsOfPanel:kAWEEffectFilterPanelKey].downloadedEffects;
    if (downloadedEffects.count > 0) {
        [availableEffects addObjectsFromArray:downloadedEffects];
    }
    NSArray *builtinEffects = [self builtinEffects];
    if (builtinEffects.count > 0) {
        [availableEffects addObjectsFromArray:builtinEffects];
    }
    return [availableEffects copy];
}

- (NSArray<IESEffectModel *> *)builtinEffects
{
    NSMutableArray *effectArray = @[].mutableCopy;
    NSArray *effectDic = ACCConfigArray(kConfigArray_filter_effect_build_in_effects_info);

    NSDictionary *coversDic = ACCConfigDict(kConfigDict_builtin_effect_covers);
    for (NSDictionary *dic in effectDic) {
        IESEffectModel *effect = [[IESEffectModel alloc] initWithDictionary:dic error:NULL];
        effect.iconDownloadURLs = [coversDic acc_arrayValueForKey:[dic acc_stringValueForKey:@"builtinIcon"]];
        effect.builtinIcon = nil;
        if (effect) {
            [effectArray addObject:effect];
        }
    }
    
    return effectArray;
}

- (IESEffectModel *)effectWithID:(NSString *)effectId
{
    if (effectId.length <= 0) {
        return nil;
    }
    
    // Hit cache
    [self.effectIdAndEffectCacheLock lock];
    IESEffectModel *model = [self.effectIdAndEffectCache objectForKey:effectId];
    [self.effectIdAndEffectCacheLock unlock];
    
    if (model) {
        return model;
    }
    
    NSArray *effectArray = [self availableEffects].copy;
    
    // Update the cache, and then check the cache
    [self.effectIdAndEffectCacheLock lock];
    for (IESEffectModel *effectModel in effectArray) {
        if (effectModel.effectIdentifier) {
            [self.effectIdAndEffectCache setObject:effectModel forKey:effectModel.effectIdentifier];
        }
    }
    model = [self.effectIdAndEffectCache objectForKey:effectId];
    [self.effectIdAndEffectCacheLock unlock];
    
    if (model) {
        return model;
    }
    
    return nil;
}

- (void)appendDownloadedEffect:(IESEffectModel *)effectModel
{
    if (effectModel.effectIdentifier) {
        [self.effectIdAndEffectCache setObject:effectModel forKey:effectModel.effectIdentifier];
    }
    if (effectModel.originalEffectID) {
        [self.effectIdAndEffectCache setObject:effectModel forKey:effectModel.originalEffectID];
    }
}

- (IESEffectModel *)effectWithName:(NSString *)name
{
    if (name.length <= 0) {
        return nil;
    }
    
    // Hit cache
    [self.effectNameAndEffectCacheLock lock];
    IESEffectModel *model = [self.effectNameAndEffectCache objectForKey:name];
    [self.effectNameAndEffectCacheLock unlock];
    if (model) {
        return model;
    }
    
    NSArray *effectArray = [self availableEffects].copy;
    
    // Update the cache, and then check the cache
    [self.effectNameAndEffectCacheLock lock];
    for (IESEffectModel *effectModel in effectArray) {
        if (effectModel.effectName) {
            [self.effectNameAndEffectCache setObject:effectModel forKey:effectModel.effectName];
        }
    }
    model = [self.effectNameAndEffectCache objectForKey:name];
    [self.effectNameAndEffectCacheLock unlock];
    if (model) {
        return model;
    }
    
    return nil;
}

- (NSString *)effectIdWithType:(IESEffectFilterType)effectType
{
    NSDictionary *effectDic = @{@(IESEffectFilterFake3D):@{@"name":@"av_filter_effect2",
                                                           @"effectId":@"15659",
                                                           },
                                @(IESEffectFilterRBVertigo):@{@"name":@"effect_illusion",
                                                              @"effectId":@"15660",
                                                              },
                                @(IESEffectFilterWhiteEdge):@{@"name":@"Black magic",
                                                              @"effectId":@"15661",
                                                              },
                                @(IESEffectFilterOldMovie):@{@"name":@"70s",
                                                             @"effectId":@"15662",
                                                             },
                                @(IESEffectFilterSoulScale):@{@"name":@"av_filter_effect1",
                                                              @"effectId":@"15658",
                                                              },
                                @(IESEffectFilterSnowFlake):@{@"name":@"X-Signal",
                                                              @"effectId":@"15663",
                                                              }};

    NSString *effectPathId = effectDic[@(effectType)][@"effectId"];

    return effectPathId;
}

- (UIColor *)maskColorForEffect:(IESEffectModel *)effect
{
    NSArray *effects = self.effectPlatformModel.effects;
    NSArray *colors = ACCConfigArray(kConfigArray_effect_colors);
    NSInteger index = effects.count > 0 ? [effects indexOfObject:effect] : NSNotFound;
    NSInteger colorIndex = 0;
    if (index != NSNotFound) {
        colorIndex = index % colors.count;
    } else {
        colorIndex = [effect.effectIdentifier integerValue] % colors.count;
    }
    
    NSString *color = colors[colorIndex];  // "#FFFFFF"
    if (color.length == 7) {
        return [[UIColor acc_colorWithHexString:color] colorWithAlphaComponent:0.9];
    }
    return ACCUIColorFromRGBA(0x0FFC9C, 0.9);
}

- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect {
    [self.lock lock];
    NSArray *downloadingEffects = [self.downloadingEffects copy];
    [self.lock unlock];
    if (!ACC_isEmptyString(effect.builtinResource) || effect.downloaded) {
        return AWEEffectDownloadStatusDownloaded;
    } else if ([downloadingEffects containsObject:effect]){
        return AWEEffectDownloadStatusDownloading;
    } else {
        return AWEEffectDownloadStatusUndownloaded;
    }
}

- (void)addNextEffectToDownloadQueue {
    NSArray *effects = self.effectPlatformModel.effects;
    if (self.nextDownloadIndex >= effects.count) {
        return;
    }
    for (NSInteger i = self.nextDownloadIndex; i < effects.count; i++) {
        IESEffectModel *effect = effects[i];
        [self.lock lock];
        NSArray *downloadingEffects = [self.downloadingEffects copy];
        [self.lock unlock];
        if (!effect.downloaded && ![downloadingEffects containsObject:effect]) {
            if (downloadingEffects.count < kAWEEffectFilterDownloadMaxConcurrent) {
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

- (void)addEffectToDownloadQueue:(IESEffectModel *)effectModel {
    [self.lock lock];
    [self.downloadingEffects addObject:effectModel];
    [self.lock unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:AWEEffectFilterDataManagerRefreshNotification object:effectModel];
    @weakify(self);
    dispatch_async(self.downloadQueue, ^{
        @strongify(self);
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        AWEEffectPlatformTrackModel *trackModel = [AWEEffectPlatformTrackModel modernStickerTrackModel];
        trackModel.successStatus = @10;
        trackModel.failStatus = @11;
        NSTimeInterval startTime = CACurrentMediaTime();
        [IESAutoInline(ACCBaseContainer(), AWEEffectPlatformManageable) downloadEffect:effectModel trackModel:trackModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            @strongify(self)
            [[NSNotificationCenter defaultCenter] postNotificationName:AWEEffectFilterDataManagerRefreshNotification object:effectModel];
              dispatch_semaphore_signal(self.semaphore);
            [self.lock lock];
              [self.downloadingEffects removeObject:effectModel];
            [self.lock unlock];
              if (self.downloadingEffects.count < kAWEEffectFilterDownloadMaxConcurrent) {
                  [self addNextEffectToDownloadQueue];
              }
            
            NSInteger duration = (CACurrentMediaTime() - startTime) * 1000;
            NSInteger success = !(error || ACC_isEmptyString(filePath));
            NSMutableDictionary *params = @{@"resource_type":@"edit_effect",
                                            @"resource_id":effectModel.effectIdentifier?:@"",
                                            @"duration":@(duration),
                                            @"status":@(success?0:1),
                                            @"error_domain":error.domain?:@"",
                                            @"error_code":@(error.code)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_resource_download"
                               params:params.copy
                      needStagingFlag:NO];
        }];
    });
}

- (AWEEffectFilterPathBlock)pathConvertBlock
{
    NSDictionary *effectDic = @{@(IESEffectFilterFake3D):@{@"name":@"av_filter_effect2",
                                                           @"effectId":@"15659",
                                                           },
                                @(IESEffectFilterRBVertigo):@{@"name":@"effect_illusion",
                                                              @"effectId":@"15660",
                                                              },
                                @(IESEffectFilterWhiteEdge):@{@"name":@"Black magic",
                                                              @"effectId":@"15661",
                                                              },
                                @(IESEffectFilterOldMovie):@{@"name":@"70s",
                                                             @"effectId":@"15662",
                                                             },
                                @(IESEffectFilterSoulScale):@{@"name":@"av_filter_effect1",
                                                              @"effectId":@"15658",
                                                              },
                                @(IESEffectFilterSnowFlake):@{@"name":@"X-Signal",
                                                              @"effectId":@"15663",
                                                              }};

    AWEEffectFilterPathBlock block = ^IESMMEffectStickerInfo *(NSString *effectPathId, IESEffectFilterType effectType) {
        IESEffectModel *effectModel = nil;

        if (effectPathId == nil) {
            effectPathId = [self effectIdWithType:effectType];
        }
        effectModel = [self effectWithID:effectPathId];

        if (effectModel == nil) {
            effectModel = [self effectWithName:effectDic[@(effectType)][@"name"]];
        }
        return [effectModel effectStickerInfo];
    };

    return block;
}

- (IESEffectPlatformResponseModel *)effectPlatformModel
{
    if (!self.p_effectPlatformModelResponseModel) {
        self.p_effectPlatformModelResponseModel = [EffectPlatform cachedEffectsOfPanel:kAWEEffectFilterPanelKey];
    }
    return self.p_effectPlatformModelResponseModel;
}

- (CGFloat)effectDurationForEffect:(IESEffectModel *)effect
{
    NSString *durationTag = nil;
    NSString *const durationPrefix = @"duration:";
    for (NSString *tag in effect.tags) {
        if ([tag hasPrefix:durationPrefix]) {
            durationTag = tag;
            break;
        }
    }
    
    if (durationTag) {
        durationTag = [durationTag stringByReplacingOccurrencesOfString:durationPrefix withString:@""];
        if (durationTag.length > 0) {
            double durationValue = [durationTag doubleValue];
            if (durationValue > 0) {
                return durationValue / 1000.0f;
            }
        }
    }
    
    return 0.5;
}

@end
