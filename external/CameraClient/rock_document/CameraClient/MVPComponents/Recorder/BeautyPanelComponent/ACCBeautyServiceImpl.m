//
//  ACCBeautyServiceImpl.m
//  Pods
//
//  Created by liyingpeng on 2020/5/27.
//

#import "ACCBeautyServiceImpl.h"

#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitComponents/ACCBeautyManager.h>
#import <CreationKitComponents/ACCBeautyDataHandler.h>
#import <CreationKitComponents/ACCBeautyComponentConfigProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyCacheMigration.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@interface ACCBeautyServiceImpl ()

@property (nonatomic, strong, readwrite) ACCBeautyPanelViewModel *beautyPanelViewModel;
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCBeautyComponentConfigProtocol> beautyComponentConfig;

@end

@implementation ACCBeautyServiceImpl
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, beautyComponentConfig, ACCBeautyComponentConfigProtocol)

@synthesize beautyOn = _beautyOn;

#pragma mark - public

- (void)clearAllComposerBeautyEffects
{
    NSArray<AWEComposerBeautyEffectWrapper *> *effects = self.effectViewModel.currentEffects;
    [self clearComposerBeautyEffects:effects];
}

- (void)clearComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers
{
    NSMutableArray *nodeTags = [NSMutableArray new];
    NSString *logInfo = @"===Composer removes effect: ";
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
        if ([effectWrapper isEffectSet]) {
            for (AWEComposerBeautyEffectWrapper *child in effectWrapper.childEffects) {
                if ([child downloaded]) {
                    [nodeTags addObjectsFromArray:[child nodesWithIntensity:NO]];
                    logInfo = [logInfo stringByAppendingFormat:@"%@", child];
                }
            }
        } else {
            if ([effectWrapper downloaded]) {
                [nodeTags addObjectsFromArray:[effectWrapper nodesWithIntensity:NO]];
                logInfo = [logInfo stringByAppendingFormat:@"%@", effectWrapper];
            }
        }
    }
    ACCLog(@"%@", logInfo);
    [self.cameraService.beauty removeComposerNodesWithTags:nodeTags];
}

- (void)applyComposerBeautyEffects:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers
{
    NSMutableArray *nodes = [NSMutableArray new];
    BOOL needAddSkeletonCallback = NO;
    NSString *logInfo = @"===Composer apply effect: ";
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
        if (!effectWrapper.isFilter && effectWrapper.effect) {
            NSString *resourcePath = effectWrapper.effect.resourcePath;
            if (ACC_isEmptyString(resourcePath)) {
                continue;
            }
            if (effectWrapper.categoryWrapper.needShowTips) {
                needAddSkeletonCallback = YES;
            }
            if (ACC_isEmptyArray(effectWrapper.items)) {
                VEComposerInfo *info = [[VEComposerInfo alloc] init];
                info.node = resourcePath;
                info.tag = effectWrapper.effect.extra;
                [nodes addObject:info];
            } else {
                float ratio = effectWrapper.currentRatio;
                for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
                    float value = [item effectValueForRatio:ratio];
                    NSString *pathTag = [NSString stringWithFormat:@"%@:%@:%f", effectWrapper.effect.resourcePath, item.tag, value];
                    VEComposerInfo *info = [[VEComposerInfo alloc] init];
                    info.node = pathTag;
                    info.tag = effectWrapper.effect.extra;
                    [nodes addObject:info];
                    ACCLog(@"apply composer beauty: %@ %f", item.tag, value);
                }
            }
            logInfo = [logInfo stringByAppendingFormat:@"%@", effectWrapper];
        }
    }
    ACCLog(@"%@", logInfo);
    [self.cameraService.beauty appendComposerNodesWithTags:nodes];
    
    if (needAddSkeletonCallback) {
        [self addSkeletonAlgorithmCallback];
    }
}

-(void)replaceComposerBeautyWithNewEffects:(nonnull NSArray *)newEffects oldEffects:(nonnull NSArray *)oldEffects
{
    NSArray *newNodes = [self p_nodesFromEffects:newEffects];
    NSArray *oldNodes = [self p_nodesFromEffects:oldEffects];
    [self.cameraService.beauty replaceComposerNodesWithNewTag:newNodes old:oldNodes];
}

- (NSArray *)p_nodesFromEffects:(NSArray *)effectWrappers
{
    NSMutableArray *nodes = [NSMutableArray new];
    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
        if (!effectWrapper.isFilter && effectWrapper.effect) {
            NSString *resourcePath = effectWrapper.effect.resourcePath;
            if (ACC_isEmptyString(resourcePath)) {
                continue;
            }
            if (ACC_isEmptyArray(effectWrapper.items)) {
                VEComposerInfo *info = [[VEComposerInfo alloc] init];
                info.node = resourcePath;
                info.tag = effectWrapper.effect.extra;
                [nodes addObject:info];
            } else {
                float ratio = effectWrapper.currentRatio;
                for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
                    float value = [item effectValueForRatio:ratio];
                    NSString *pathTag = [NSString stringWithFormat:@"%@:%@:%f", effectWrapper.effect.resourcePath, item.tag, value];
                    VEComposerInfo *info = [[VEComposerInfo alloc] init];
                    info.node = pathTag;
                    info.tag = effectWrapper.effect.extra;
                    [nodes addObject:info];
                }
            }
        }
    }
    return nodes;
}

/// only beauty of skeleton category should register skeleton algorithm result call back
/// @param beautyWrapper AWEComposerBeautyEffectWrapper *
- (void)addAlgorithmCallbackForBeauty:(AWEComposerBeautyEffectWrapper *)beautyWrapper
{
    if (beautyWrapper.categoryWrapper.needShowTips) {
        [self addSkeletonAlgorithmCallback];
    }
}

/*
   register skeleton algorithm call back, that we can
   get the result data from VE call back。
   only if we register that VE can handle algorithm result
   如果在初始化相机时就启动相关算法，由于算法需要的模型还没有下载下来，会导致算法初始化失败。
   之后虽然美颜小项的资源包加载时也会启动算法，但是由于一开始初始化失败，导致一直失败
*/
- (void)addSkeletonAlgorithmCallback
{
    if (!(self.cameraService.algorithm.externalAlgorithm & IESMMAlgorithm_Skeleton2)) {
        [self.cameraService.algorithm appendAlgorithm:IESMMAlgorithm_Skeleton2];
    }
}

- (BOOL)isUsingLocalBeautyResource
{
    return self.effectViewModel.availableEffects.lastObject.isLocalEffect;
}

- (void)updateAvailabilityForEffectsInCategories:(NSArray *)categories
{
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in categories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if (![effectWrapper isEffectSet]) {
                effectWrapper.available = [self availabilityForEffectWrapper:effectWrapper withCameraService:self.cameraService];
            } else {
                effectWrapper.available = YES;
                BOOL atLeastOneChildAvailable = NO;
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    childEffect.available = [self availabilityForEffectWrapper:childEffect withCameraService:self.cameraService];
                    if (childEffect.available) {
                        atLeastOneChildAvailable = YES;
                    }
                }
                effectWrapper.available = atLeastOneChildAvailable;
            }
        }
    }
}

- (BOOL)availabilityForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
                   withCameraService:(id<ACCCameraService>)cameraService
{
    BOOL available = YES;
    NSString *resourcePath = effectWrapper.effect.resourcePath;
    if (ACC_isEmptyString(resourcePath)) {
        return NO;
    }
    if (ACC_isEmptyArray(effectWrapper.items)) {
        IESComposerJudgeResult *judgeResult = [cameraService.effect judgeComposerPriority:effectWrapper.effect.resourcePath tag:@""];
        NSInteger result = judgeResult.result;
        if (result < 0) {
            available = NO;
        }
    } else {
        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
            IESComposerJudgeResult *judgeResult = [cameraService.effect judgeComposerPriority:effectWrapper.effect.resourcePath tag:[item tag]];
            NSInteger result = judgeResult.result;
            if (result < 0) {
                available = NO;
                break;
            }
        }
    }
    return available;
}

#pragma mark - beauty apply

#pragma mark - getter & setter

- (BOOL)beautyOn
{
    NSNumber *beautyOn = [ACCCache() objectForKey:HTSVideoRecorderBeautyKey];
    if (beautyOn == nil) {
        return YES;
    } else {
        return [beautyOn boolValue];
    }
}

- (BOOL)isUsingBeauty
{
    BOOL usedBeauty = NO;
    for (AWEComposerBeautyEffectWrapper *effect in self.effectViewModel.currentEffects) {
        if (effect.currentRatio != 0) {
            usedBeauty = YES;
            break;
        }
    }
    
    return usedBeauty;
}

- (void)setBeautyOn:(BOOL)beautyOn
{
    [ACCCache() setBool:beautyOn forKey:HTSVideoRecorderBeautyKey];
}

- (ACCBeautyPanelViewModel *)beautyPanelViewModel {
    if (!_beautyPanelViewModel) {
        // here business name default is nil, Douyin no need to set
        _beautyPanelViewModel = [[ACCBeautyPanelViewModel alloc] initWithBusinessName:@""];
    }
    return _beautyPanelViewModel;
}

- (AWEComposerBeautyEffectViewModel *)effectViewModel {
    if (!_effectViewModel) {
        AWEComposerBeautyCacheViewModel *cacheModel = [[AWEComposerBeautyCacheViewModel alloc] initWithBusinessName:self.beautyPanelViewModel.businessName];
        ACCBeautyDataHandler *dataHandler = [[ACCBeautyDataHandler alloc]init];
        AWEComposerBeautyCacheMigration *cacheMigrationManager = [[AWEComposerBeautyCacheMigration alloc] initWithCacheManager:cacheModel panelName:@""];
        NSString *beautyPanelName = nil;
        if ([self.beautyComponentConfig respondsToSelector:@selector(beautyPanelName)]) {
            beautyPanelName = [self.beautyComponentConfig beautyPanelName];
        }
        _effectViewModel = [[AWEComposerBeautyEffectViewModel alloc] initWithCacheViewModel:cacheModel
                                                                                  panelName:beautyPanelName
                                                                           migrationHandler:cacheMigrationManager
                                                                                dataHandler:dataHandler];
        [[ACCBeautyManager defaultManager] setComposerEffectVM:_effectViewModel];
    }
    return _effectViewModel;
}

- (void)cacheSelectedFilter:(nonnull NSString *)filterID
         withCameraPosition:(AVCaptureDevicePosition)cameraPosition
{
    AWEComposerBeautyCameraPosition beautyCameraPosition = cameraPosition == AVCaptureDevicePositionBack ? AWEComposerBeautyCameraPositionFront : AWEComposerBeautyCameraPositionBack;
    [self.effectViewModel.cacheObj cacheSelectedFilter:filterID withCameraPosition:beautyCameraPosition];
}

- (void)syncFrontAndRearFilterId:(nonnull NSString *)filterId
{
    AWEComposerBeautyCameraPosition cameraPosition = self.cameraService.cameraControl.currentCameraPosition == AVCaptureDevicePositionBack ? AWEComposerBeautyCameraPositionFront : AWEComposerBeautyCameraPositionBack;
    [self.effectViewModel.cacheObj cacheSelectedFilter:filterId withCameraPosition:cameraPosition];
}

- (void)updateAppliedFilter:(nonnull IESEffectModel *)filterModel
{
    [self.effectViewModel updateAppliedFilter:filterModel];
}

@end
