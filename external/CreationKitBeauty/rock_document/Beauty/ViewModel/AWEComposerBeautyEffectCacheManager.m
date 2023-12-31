//
//  AWEComposerBeautyEffectCacheManager.m
//  CameraClient
//
//  Created by HuangHongsen on 2020/3/10.
//

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCacheManager.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>

@interface AWEComposerBeautyEffectCacheManager()

@property (nonatomic, copy) NSDictionary *resourceIDCacheKeyMapping;
@property (nonatomic, strong) AWEComposerBeautyEffectViewModel *effectViewModel;

@end

#define kAWEComposerBeautyResourceIDEffectIDMappingCacheKey @"kAWEComposerBeautyResourceIDEffectIDMappingCacheKey"

@implementation AWEComposerBeautyEffectCacheManager

#pragma mark - Initialization

+ (AWEComposerBeautyEffectCacheManager *)sharedManager
{
    static AWEComposerBeautyEffectCacheManager *sharedInstance;
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[AWEComposerBeautyEffectCacheManager alloc] init];
        });
    }
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

#pragma mark - Public APIs

- (void)updateWithBeautyEffectViewModel:(AWEComposerBeautyEffectViewModel *)effectViewModel
{
    self.effectViewModel = effectViewModel;
}

- (double)ratioForEffectWithResourceID:(NSString *)resourceID
                                   tag:(NSString *)tag
                                gender:(AWEComposerBeautyGender)gender
{
    AWEComposerBeautyEffectWrapper *effectWrapper = [self p_findEffectWrapperByResourceID:resourceID];
    if (!effectWrapper) {
        return CGFLOAT_MIN;
    } else {
        if (!tag) {
            return [self.effectViewModel.cacheObj ratioForEffect:effectWrapper gender: gender];
        }
        return [self.effectViewModel.cacheObj ratioForEffect:effectWrapper tag:tag gender:gender];
    }
}

- (void)setRatio:(double)ratio forEffectWithResourceID:(NSString *)resourceID tag:(NSString *)tag gender:(AWEComposerBeautyGender)gender
{
    AWEComposerBeautyEffectWrapper *effectWrapper = [self p_findEffectWrapperByResourceID:resourceID];
    if (effectWrapper) {
        if (tag) {
            AWEComposerBeautyEffectItem *firstItem = [effectWrapper.items firstObject];
            if ([tag isEqualToString:firstItem.tag] && self.effectViewModel.currentGender == gender) {
                effectWrapper.currentRatio = ratio;
            }
            [self.effectViewModel.cacheObj setRatio:ratio forEffect:effectWrapper tag:tag gender:gender];
        } else {
            if (self.effectViewModel.currentGender == gender) {
                effectWrapper.currentRatio = ratio;
            }
            [self.effectViewModel.cacheObj setRatio:ratio forEffect:effectWrapper gender:gender];
        }
    }
}

- (void)applySecondaryComposerItemWithResourceID:(NSString *)resourceID
                                          gender:(AWEComposerBeautyGender)gender
{
    AWEComposerBeautyEffectWrapper *effectWrapper = [self p_findEffectWrapperByResourceID:resourceID];
    if (![effectWrapper.parentEffect isEffectSet]) {
        return;
    }
    
    if (self.effectViewModel.currentGender != gender) {
        [self.effectViewModel updateAppliedChildEffect:effectWrapper
                                             forEffect:effectWrapper.parentEffect
                                                gender:gender];
    } else {
        [self.effectViewModel updateAppliedChildEffect:effectWrapper
                                             forEffect:effectWrapper.parentEffect];
    }
}

- (NSArray *)resourceIDsForAppliedEffectsForGender:(AWEComposerBeautyGender)gender
{
    NSMutableArray *resourceIDs = [NSMutableArray array];
    NSArray *appliedEffects = self.effectViewModel.currentEffects;
    for (AWEComposerBeautyEffectWrapper *effectWrapper in appliedEffects) {
        if (effectWrapper.effect.resourceId) {
            [resourceIDs acc_addObject:effectWrapper.effect.resourceId];
        }
    }
    return [resourceIDs copy];
}

- (BOOL)userHasModifiedBeautyConfigInCameraPage
{
    return self.effectViewModel.didModifyStatus;
}

- (AWEComposerBeautyGender)currentGender
{
    return self.effectViewModel.currentGender;
}

- (void)cleanUpUnifiedBeautyResource
{
    self.effectViewModel = nil;
}

- (AWEComposerBeautyEffectViewModel *)effectViewModel
{
    if (!_effectViewModel) {
        AWEComposerBeautyCacheViewModel *cacheModel = [[AWEComposerBeautyCacheViewModel alloc] initWithBusinessName:@""];
        _effectViewModel = [[AWEComposerBeautyEffectViewModel alloc] initWithCacheViewModel:cacheModel panelName:nil];
        [_effectViewModel prepareDataSource];
    }
    return _effectViewModel;
}

#pragma mark - Private Helpers

- (AWEComposerBeautyEffectWrapper *)p_findEffectWrapperByResourceID:(NSString *)resourceID
{
    if (!resourceID) {
        return nil;
    }
    for (AWEComposerBeautyEffectWrapper *effectWrapper in self.effectViewModel.availableEffects) {
        if ([effectWrapper.effect.resourceId isEqualToString:resourceID]) {
            return effectWrapper;
        }
    }
    return nil;
}


@end
