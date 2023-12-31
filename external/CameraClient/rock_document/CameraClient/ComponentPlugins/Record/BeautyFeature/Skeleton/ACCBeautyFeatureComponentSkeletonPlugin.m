//
//  ACCBeautyFeatureComponentSkeletonPlugin.m
//  CameraClient-Pods-CameraClient
//
//  Created by hehai.howie on 2021/04/20.
//

#import "ACCBeautyFeatureComponentSkeletonPlugin.h"
#import <CreationKitComponents/ACCBeautyFeatureComponent.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CameraClient/ACCSkeletonDetectTipsManager.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreativeKit/ACCMacros.h>


@interface ACCBeautyFeatureComponentSkeletonPlugin () <ACCAlgorithmEvent>

@property (nonatomic, strong, readonly) ACCBeautyFeatureComponent *hostComponent;
@property (nonatomic, assign) BOOL hadDetectSkeleton;
@property (nonatomic, strong) ACCSkeletonDetectTipsManager *skeletonTipsManager;

@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@end

@implementation ACCBeautyFeatureComponentSkeletonPlugin

IESAutoInject(self.hostComponent.serviceProvider, switchModeService, ACCRecordSwitchModeService)

@synthesize component = _component;

- (void)dealloc
{
    [_skeletonTipsManager removeTips];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (void)loadComponentView
{
    ACCBeautyFeatureComponent *component = self.hostComponent;
    @weakify(self);
    [[[RACSignal merge:@[component.beautyPanel.composerVM.currentCategorySignal,
                         component.beautyPanel.composerVM.selectedEffectSignal,
                         component.modernBeautyButtonClickedSignal,
                         component.beautyPanelDismissSignal,
                         component.composerBeautyDidFinishSlidingSignal
    ]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_updateDetectTips];
    }];
}

#pragma mark - ACCFeatureComponentPlugin

+ (id)hostIdentifier
{
    return [ACCBeautyFeatureComponent class];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    id<ACCCameraService> cameraService = IESAutoInline(serviceProvider, ACCCameraService);
    [cameraService.algorithm addSubscriber:self];
}

- (void)p_updateDetectTips
{
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = self.hostComponent.beautyPanel.composerVM.currentCategory;
    if (currentCategory.needShowTips
        && ![self categoryHasAllZeroIdentify:currentCategory]
        && !self.hadDetectSkeleton
        && self.hostComponent.isShowingBeautyPanel) {
        [self.skeletonTipsManager showNotDetectedTips];
    } else {
        [self.skeletonTipsManager removeTips];
    }
}

- (void)onExternalAlgorithmCallback:(NSArray<IESMMAlgorithmResultData *> *)result
                               type:(IESMMAlgorithm)type {
    
    if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive) {
        return;
    }
    
    // handle body skeleton detect result only when type is skeleton
    if (type == IESMMAlgorithm_Skeleton2) {
        BOOL hasBodySkeleton = NO;
        for (IESMMAlgorithmResultData *data in result) {
            if (data.algorithmType == IESMMAlgorithm_Skeleton2) {
                hasBodySkeleton = YES;
            }
        }
        self.hadDetectSkeleton = hasBodySkeleton;
        return;
    }
}

#pragma mark - Private

- (BOOL)categoryHasAllZeroIdentify:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
        if (!ACC_FLOAT_EQUAL_ZERO(effectWrapper.currentRatio) && effectWrapper.available) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Properties

- (ACCBeautyFeatureComponent *)hostComponent
{
    return self.component;
}

- (ACCSkeletonDetectTipsManager *)skeletonTipsManager
{
    if (!_skeletonTipsManager) {
        _skeletonTipsManager = [[ACCSkeletonDetectTipsManager alloc] init];
    }
    return _skeletonTipsManager;
}

- (void)setHadDetectSkeleton:(BOOL)hadDetectSkeleton
{
    if (_hadDetectSkeleton != hadDetectSkeleton) {
        _hadDetectSkeleton = hadDetectSkeleton;
        [self p_updateDetectTips];
    }
}

@end
