//
//  ACCDuetTemplateComponent.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/14.
//

#import "ACCDuetTemplateComponent.h"
#import "ACCDuetTemplateViewController.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <CreationKitArch/ACCRecordMode.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@interface ACCDuetTemplateComponent () <ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) ACCDuetTemplateViewController *duetTemplateViewController;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCFilterService> filterService;

@end

@implementation ACCDuetTemplateComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.cameraService addSubscriber:self];
}

- (ACCDuetTemplateViewController *)p_initDuetTemplateViewController
{
    if (!_duetTemplateViewController) {
        _duetTemplateViewController = [self duetTemplateVC];
    }
    return _duetTemplateViewController;
}

- (ACCDuetTemplateViewController *)duetTemplateVC
{
    @weakify(self);
    dispatch_block_t closeBlock = ^{
        @strongify(self);
        [self close];
    };
    dispatch_block_t willEnterDetailVCBlock = ^{
        @strongify(self);
        self.viewContainer.switchModeContainerView.hidden = YES;
    };
    dispatch_block_t didAppearBlock = ^{
        @strongify(self);
        self.viewContainer.switchModeContainerView.hidden = NO;
    };
    ACCDuetTemplateViewController *duetTemplateVC = [[ACCDuetTemplateViewController alloc] init];
    
    duetTemplateVC.closeBlock = closeBlock;
    duetTemplateVC.willEnterDetailVCBlock = willEnterDetailVCBlock;
    duetTemplateVC.didAppearBlock = didAppearBlock;
    
    return duetTemplateVC;
}


#pragma mark - ACCComponentProtocol

- (void)enterDuetMode
{
    if (self.duetTemplateViewController) {
        return;
    }
    acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.cameraService.cameraControl stopVideoAndAudioCapture];
    });
    
    if (self.viewContainer.switchModeContainerView) {
        self.duetTemplateViewController = [self p_initDuetTemplateViewController];
        self.duetTemplateViewController.publishViewModel = self.repository;
        self.filterService.panGestureRecognizerEnabled = NO;
        
        [self.controller.root addChildViewController:self.duetTemplateViewController];
        [self.cameraService.cameraControl stopVideoCapture];
        
        self.duetTemplateViewController.view.alpha = 0;
        [self.viewContainer.modeSwitchView insertSubview:self.duetTemplateViewController.view belowSubview:self.viewContainer.switchModeContainerView];
        [UIView animateWithDuration:0.2 animations:^{
            self.duetTemplateViewController.view.alpha = 1;
        }];
        
        [self.duetTemplateViewController didMoveToParentViewController:self.controller.root];
        NSString *enterMethod = self.repository.repoTrack.enterMethod;
        NSString *toStatus = self.duetTemplateViewController.initialSelectedIndex == 0 ? @"duet_for_shoot" : @"duet_for_sing";
        if (![enterMethod isEqualToString:@"from_existed_page"]) {
            NSDictionary *params = @{
                @"enter_from" : self.repository.repoTrack.enterFrom,
                @"to_status" : toStatus,
                @"creation_id" : self.repository.repoContext.createId ?: @"",
                @"shoot_way" : self.repository.repoTrack.referString ?: @"",
            };
            [ACCTracker() trackEvent:@"enter_duet_shoot_page" params:params];
        }
    }
}

- (void)exitDuetMode
{
    [self.duetTemplateViewController willMoveToParentViewController:nil];
    [self.duetTemplateViewController.view removeFromSuperview];
    [self.duetTemplateViewController removeFromParentViewController];
    self.duetTemplateViewController = nil;
    BOOL hideExceptToolBar = (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive);
    [self.viewContainer showItems:!hideExceptToolBar animated:NO];
}

- (void)close
{
    [self.controller close];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.modeId == ACCRecordModeDuet) {
        [self.cameraService.cameraControl stopVideoAndAudioCapture];
        [self enterDuetMode];
    } else if (oldMode.modeId == ACCRecordModeDuet) {
        [self exitDuetMode];
    }
}
@end
