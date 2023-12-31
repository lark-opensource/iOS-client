//
//  ACCRecordSubmodeViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2020/12/21.
//

#import "ACCRecordSubmodeViewModel.h"

#import <CreativeKit/NSArray+ACCAdditions.h>

#import "ACCRecordContainerMode.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordPropService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import "ACCKaraokeService.h"
#import "ACCFlowerService.h"

@interface ACCRecordSubmodeViewModel ()

@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;


@property (nonatomic, readonly) NSInteger cellCount;
@property (nonatomic, strong) NSDictionary<NSValue *, NSString *> *switchMethodMap;

@end

@implementation ACCRecordSubmodeViewModel

IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESOptionalInject(self.serviceProvider, flowerService, ACCFlowerService)

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.swipeGestureEnabled) {
        return NO;
    }
    UIView *containerView = gestureRecognizer.view;
    CGPoint touchPos = [gestureRecognizer locationInView:containerView];
    return CGRectContainsPoint(self.gestureResponseArea, touchPos);
}

#pragma mark - Swipe Gestures Handling

- (void)swipeSwitchSubmode:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        return;
    }
    if (self.flowService.videoSegmentsCount > 0 || !self.containerMode) {
        return;
    }

    UISwipeGestureRecognizer *swipeGesture = (UISwipeGestureRecognizer *)gestureRecognizer;
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        self.switchMethod = submodeSwitchMethodFullScreenSlide;
        if (swipeGesture.direction == UISwipeGestureRecognizerDirectionRight) {
            if (self.modeIndex > 0) {
                self.modeIndex--;
            }
        } else if (swipeGesture.direction == UISwipeGestureRecognizerDirectionLeft) {
            if (self.modeIndex < self.containerMode.submodes.count - 1) {
                self.modeIndex++;
            }
        }
    }
}

#pragma mark - Getter & Setter

- (void)setModeIndex:(NSInteger)modeIndex
{
    if (modeIndex == _modeIndex) {
        return;
    }
    _modeIndex = modeIndex;
    ACCRecordMode *mode = [self.containerMode.submodes acc_objectAtIndex:self.modeIndex];
    if (mode) {
        [self.switchModeService switchMode:mode];
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab)) {
            [ACCTapticEngineManager tap];
        }
    }
}

- (void)setContainerMode:(ACCRecordContainerMode *)containerMode
{
    _containerMode = containerMode;
    if (containerMode) {
        _modeIndex = containerMode.currentIndex;
    }
}

- (NSString *)switchMethodString
{
    return self.switchMethodMap[@(self.switchMethod)];
}

- (void)close
{
    self.modeIndex = self.containerMode.defaultIndex;
}

- (NSDictionary<NSValue *,NSString *> *)switchMethodMap
{
    if (!_switchMethodMap) {
        _switchMethodMap = @{
            @(submodeSwitchMethodTabBarSlide): @"tab_bar_slide",
            @(submodeSwitchMethodTabBarClick): @"tab_bar_click",
            @(submodeSwitchMethodFullScreenSlide): @"full_slide",
            @(submodeSwitchMethodClickCross): @"cross",
        };
    }
    return _switchMethodMap;
}

- (void)setSwitchLengthViewHidden:(BOOL)switchLengthViewHidden
{
    BOOL isReshoot = self.repository.repoReshoot.isReshoot;
    BOOL hasRecordOnePiece = self.repository.repoVideoInfo.fragmentInfo.count > 0;
    BOOL isDuet = self.inputData.publishModel.repoDuet.isDuet;
    BOOL shouldHideSwitchLengthView = !self.containerMode || self.containerMode.submodes.count <= 0 || isReshoot || hasRecordOnePiece || isDuet || self.viewContainer.isShowingPanel || self.quickAlbumShow || (self.propService.prop.isMultiSegProp && !self.switchModeService.currentRecordMode.isPhoto) || self.viewContainer.shouldClearUI || self.karaokeService.inKaraokeRecordPage || self.flowerService.inFlowerPropMode;
    _switchLengthViewHidden = shouldHideSwitchLengthView || switchLengthViewHidden;
}

- (void)setSwipeGestureEnabled:(BOOL)swipeGestureEnabled
{
    BOOL ABRequirements = ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab) && !ACCConfigBool(kConfigInt_enable_record_left_slide_dismiss);
    BOOL notKaraoke = !self.karaokeService.inKaraokeRecordPage;
    BOOL notIM = !self.inputData.publishModel.repoContext.isIMRecord;
    BOOL notFlowerPanel = !self.flowerService.inFlowerPropMode;
    _swipeGestureEnabled = swipeGestureEnabled && ABRequirements && notKaraoke && notIM && notFlowerPanel;
    
}

@end
