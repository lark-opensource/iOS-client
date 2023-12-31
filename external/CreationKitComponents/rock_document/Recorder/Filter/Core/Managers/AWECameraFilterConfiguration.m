//
//  AWECameraFilterConfiguration.m
//  Aweme
//
//Created by Hao Yipeng on November 8, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import "AWECameraFilterConfiguration.h"
#import "ACCFilterConfigKeyDefines.h"
#import <CreationKitArch/AWEColorFilterDataManager.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreativeKit/ACCMacros.h>

//Post filter
NSString *const kAWECameraFilterConfigurationUserSetRearFilterKey = @"kAWECameraFilterConfigurationUserSetRearFilterKey";
NSString *const kAWECameraFilterConfigurationRearFilterKey = @"kAWECameraFilterConfigurationRearFilterKey";

NSString *const kAWECameraFilterConfigurationUserSetNeedRecoverRearFilterKey = @"kAWECameraFilterConfigurationUserSetNeedRecoverRearFilterKey";
NSString *const kAWECameraFilterConfigurationNeedRecoverRearFilterKey = @"kAWECameraFilterConfigurationNeedRecoverRearFilterKey";

//Prefilter
NSString *const kAWECameraFilterConfigurationUserSetFrontFilterKey = @"kAWECameraFilterConfigurationUserSetFrontFilterKey";
NSString *const kAWECameraFilterConfigurationFrontFilterKey = @"kAWECameraFilterConfigurationFrontFilterKey";
NSString *const kAWECameraFilterConfigurationUserSetNeedRecoverFrontFilterKey = @"kAWECameraFilterConfigurationUserSetNeedRecoverFrontFilterKey";
NSString *const kAWECameraFilterConfigurationNeedRecoverFrontFilterKey = @"kAWECameraFilterConfigurationNeedRecoverFrontFilterKey";

@interface AWECameraFilterConfiguration ()

@property (nonatomic, copy, readwrite) NSArray *filterArray;
@property (nonatomic, copy, readwrite) NSArray *aggregatedEffects;

@end

@implementation AWECameraFilterConfiguration

- (instancetype)init
{
    self = [super init];
    if (self) {
        _filterManager = [AWEColorFilterDataManager defaultManager];
    }
    return self;
}

- (instancetype)initWithFilterManager:(AWEColorFilterDataManager *)filterManager
{
    self = [super init];
    if (self) {
        _filterManager = filterManager;
    }
    return self;
}

- (void)updateFilterData
{
    NSMutableArray *avaliableFilters = [[self.filterManager availableEffects] mutableCopy];
    [self updateCameraFilterWithEffects:avaliableFilters];
}

- (void)updateFilterDataWithCompletion:(dispatch_block_t)completion {
    if (_filterArray) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    if (self.fetchDataOpt) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *avaliableFilters = [[self.filterManager availableEffects] mutableCopy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCameraFilterWithEffects:avaliableFilters];
                ACCBLOCK_INVOKE(completion);
            });
        });
    } else {
        NSMutableArray *avaliableFilters = [[self.filterManager availableEffects] mutableCopy];
        [self updateCameraFilterWithEffects:avaliableFilters];
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)updateCameraFilterWithEffects:(NSMutableArray *)avaliableFilters {
    //build a fake filter which indensity is zero and change its name
    if (avaliableFilters.count > 1 && ACCConfigBool(kConfigBool_insert_normal_filter)) {
        IESEffectModel *normalModel = [avaliableFilters[1] copy];
        [normalModel setValue:ACCConfigString(kConfigString_insert_normal_filter_name_display) forKey:@"effectName"];
        [normalModel setValue:[NSString stringWithFormat:@"%@_story_normal",normalModel.effectIdentifier] forKey:@"effectIdentifier"];
        [normalModel setValue:[NSString stringWithFormat:@"%@_story_normal",normalModel.sourceIdentifier] forKey:@"sourceIdentifier"];
        [normalModel setValue:[NSString stringWithFormat:@"%@_story_normal",normalModel.resourceID] forKey:@"resourceID"];
        [normalModel setValue:[NSString stringWithFormat:@"%@_story_normal",normalModel.resourceId] forKey:@"resourceId"];
        normalModel.isEmptyFilter = YES;
        [avaliableFilters insertObject:normalModel atIndex:0];
    }
    
    _filterArray = [avaliableFilters copy];
    _aggregatedEffects = [[self.filterManager aggregatedEffects] copy];
    if ([_filterArray containsObject:self.filterManager.frontCameraFilter]) {
        _frontCameraFilter = self.filterManager.frontCameraFilter;
    } else {
        _frontCameraFilter = [self.filterManager normalFilter];
    }
    if ([_filterArray containsObject:self.filterManager.rearCameraFilter]) {
        _rearCameraFilter = self.filterManager.rearCameraFilter;
    } else {
        _rearCameraFilter = [self.filterManager normalFilter];
    }

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    // do not restore filter if deselected intentionally
    if ([self hadDeselectedRearFilter] || !ACCConfigBool(kConfigBool_add_last_used_filter)) {
        _rearCameraFilter = nil;
        _needRecoveryRearCameraFilter = nil;
    } else {
        BOOL hasSetRearFilter = [userDefaults boolForKey:kAWECameraFilterConfigurationUserSetRearFilterKey];
        BOOL hasSetNeedRecoverRearFilter = [userDefaults boolForKey:kAWECameraFilterConfigurationUserSetNeedRecoverRearFilterKey];
        for (IESEffectModel *filter in _filterArray) {
            if (hasSetRearFilter && [self hadSelectRearFilter:filter]) {
                _rearCameraFilter = filter;
            }
            if (hasSetNeedRecoverRearFilter && [self isNeedRecoverRearFilter:filter]) {
                _needRecoveryRearCameraFilter = filter;
            }
        }
        if (!_needRecoveryRearCameraFilter) {
            _needRecoveryRearCameraFilter = [self.filterManager normalFilter];
        }
    }

    // do not restore filter if deselected intentionally
    if ([self hadDeselectedFrontFilter] || !ACCConfigBool(kConfigBool_add_last_used_filter)) {
        _frontCameraFilter = nil;
        _needRecoveryFrontCameraFilter = nil;
    } else {
        BOOL hasSetFrontFilter = [userDefaults boolForKey:kAWECameraFilterConfigurationUserSetFrontFilterKey];
        BOOL hasSetNeedRecoverFrontFilter = [userDefaults boolForKey:kAWECameraFilterConfigurationUserSetNeedRecoverFrontFilterKey];

        for (IESEffectModel *filter in _filterArray) {
            if (hasSetFrontFilter && [self hadSelectFrontFilter:filter]) {
                _frontCameraFilter = filter;
            }
            if (hasSetNeedRecoverFrontFilter && [self isNeedRecoverFrontFilter:filter]) {
                _needRecoveryFrontCameraFilter = filter;
            }
        }
        if (!_needRecoveryFrontCameraFilter) {
            _needRecoveryFrontCameraFilter = [self.filterManager normalFilter];
        }
    }
}

- (void)fetchEffectListStateCompletion:(EffectPlatformFetchListCompletionBlock)completion
{
    [self.filterManager fetchEffectListStateCompletion:completion];
}

- (void)updateFilterCheckStatusWithCheckArray:(NSArray *)checkArray uncheckArray:(NSArray *)uncheckArray
{
    [self.filterManager updateEffectListStateWithCheckArray:checkArray uncheckArray:uncheckArray];
}

- (void)setRearCameraFilter:(IESEffectModel *)rearCameraFilter
{
    BOOL needCache = ![_rearCameraFilter.effectIdentifier isEqualToString:rearCameraFilter.effectIdentifier];
    _rearCameraFilter = rearCameraFilter;
    
    if (needCache) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetRearFilterKey]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAWECameraFilterConfigurationUserSetRearFilterKey];
        }

        [[NSUserDefaults standardUserDefaults] setObject:rearCameraFilter.resourceId forKey:kAWECameraFilterConfigurationRearFilterKey];
    }
}

- (void)setFrontCameraFilter:(IESEffectModel *)frontCameraFilter
{
    BOOL needCache = ![_frontCameraFilter.effectIdentifier isEqualToString:frontCameraFilter.effectIdentifier];
    _frontCameraFilter = frontCameraFilter;
    
    if (needCache) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetFrontFilterKey]) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAWECameraFilterConfigurationUserSetFrontFilterKey];
        }

        [[NSUserDefaults standardUserDefaults] setObject:frontCameraFilter.resourceId forKey:kAWECameraFilterConfigurationFrontFilterKey];
    }
}

- (void)setNeedRecoveryFrontCameraFilter:(IESEffectModel *)needRecoveryFrontCameraFilter
{
    _needRecoveryFrontCameraFilter = needRecoveryFrontCameraFilter;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetNeedRecoverFrontFilterKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAWECameraFilterConfigurationUserSetNeedRecoverFrontFilterKey];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:needRecoveryFrontCameraFilter.resourceId forKey:kAWECameraFilterConfigurationNeedRecoverFrontFilterKey];
}

- (void)setNeedRecoveryRearCameraFilter:(IESEffectModel *)needRecoveryRearCameraFilter
{
    _needRecoveryRearCameraFilter = needRecoveryRearCameraFilter;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetNeedRecoverRearFilterKey]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAWECameraFilterConfigurationUserSetNeedRecoverRearFilterKey];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:needRecoveryRearCameraFilter.resourceId forKey:kAWECameraFilterConfigurationNeedRecoverRearFilterKey];
}

- (BOOL)hadSelectFrontFilter:(IESEffectModel *)effect {
    NSString *cachedId = [[NSUserDefaults standardUserDefaults] stringForKey:kAWECameraFilterConfigurationFrontFilterKey] ?: @"";
    if ([effect.resourceId isEqualToString:cachedId]) {
        return YES;
    } else {
        return [effect.effectIdentifier isEqualToString:cachedId];
    }
}

- (BOOL)hadDeselectedRearFilter
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetRearFilterKey] &&
    [[NSUserDefaults standardUserDefaults] objectForKey:kAWECameraFilterConfigurationRearFilterKey] == nil;
}

- (BOOL)hadDeselectedFrontFilter
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAWECameraFilterConfigurationUserSetFrontFilterKey] &&
    [[NSUserDefaults standardUserDefaults] objectForKey:kAWECameraFilterConfigurationFrontFilterKey] == nil;
}

- (BOOL)hadSelectRearFilter:(IESEffectModel *)effect {
    NSString *cachedId = [[NSUserDefaults standardUserDefaults] stringForKey:kAWECameraFilterConfigurationRearFilterKey] ?: @"";
    if ([effect.resourceId isEqualToString:cachedId]) {
        return YES;
    } else {
        return [effect.effectIdentifier isEqualToString:cachedId];
    }
}

- (BOOL)isNeedRecoverFrontFilter:(IESEffectModel *)effect {
    NSString *cachedId = [[NSUserDefaults standardUserDefaults] stringForKey:kAWECameraFilterConfigurationNeedRecoverFrontFilterKey] ?: @"";
    if ([effect.resourceId isEqualToString:cachedId]) {
        return YES;
    } else {
        return [effect.effectIdentifier isEqualToString:cachedId];
    }
}

- (BOOL)isNeedRecoverRearFilter:(IESEffectModel *)effect {
    NSString *cachedId = [[NSUserDefaults standardUserDefaults] stringForKey:kAWECameraFilterConfigurationNeedRecoverRearFilterKey] ?: @"";
    if ([effect.resourceId isEqualToString:cachedId]) {
        return YES;
    } else {
        return [effect.effectIdentifier isEqualToString:cachedId];
    }
}

@end
