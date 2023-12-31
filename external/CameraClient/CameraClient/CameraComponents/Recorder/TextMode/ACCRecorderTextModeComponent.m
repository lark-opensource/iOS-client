//
//  ACCRecorderTextModeComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/20.
//

#import "AWERepoStickerModel.h"
#import "ACCRecorderTextModeComponent.h"
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCRecorderTextModePreviewViewController.h"
#import "ACCPropViewModel.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import "AWEMVTemplateModel.h"
#import "ACCMVTemplateManagerProtocol.h"
#import "ACCRecordTextModeColorManager.h"
#import "ACCStickerLoggerImpl.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCRecordSubmodeViewModel.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCRecorderBackgroundManagerProtocol.h"
#import "ACCVideoPublishProtocol.h"
#import "ACCRepoTextModeModel.h"
#import "AWERepoPublishConfigModel.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "ACCRecorderTextModeViewModel.h"

@interface ACCRecorderTextModeComponent () <ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) ACCRecorderTextModePreviewViewController *textPreviewViewController;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, strong) AWEVideoPublishViewModel *textPublishModel;
@property (nonatomic, strong) id<ACCMVTemplateManagerProtocol> templateManager;
@property (nonatomic, strong) ACCRecordTextModeColorManager *colorManager;
@property (nonatomic, assign) BOOL hasFetchedMCTemplate;
@property (nonatomic, strong) ACCRecordSubmodeViewModel *submodeViewModel;
@property (nonatomic, strong) NSObject<ACCRecorderBackgroundSwitcherProtocol> *backgroundManager;
@property (nonatomic, strong) ACCRecorderTextModeViewModel *viewModel;

@end

@implementation ACCRecorderTextModeComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService);
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer);
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)


- (void)componentDidMount
{
    if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds) && _backgroundManager == nil) {
        acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.backgroundManager preloadInitBackground];
        });
    }
}

- (void)componentDidAppear
{
    if (!self.hasFetchedMCTemplate) {
        [[AWEMVTemplateModel sharedManager] prefetchTextToVideoTemplates];
        self.hasFetchedMCTemplate = YES;
    }
}

- (void)componentDidUnmount
{
    [self.viewModel onCleared];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCTextModeService),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
}

- (void)enterTextMode
{
    if (self.textPreviewViewController) {
        return;
    }

    acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.cameraService.cameraControl stopVideoAndAudioCapture];
    });
    [ACCCustomFont() prefetchFontEffects];

    if (self.viewContainer.switchModeContainerView) {
        @weakify(self);
        ACCRecorderTextModePreviewViewController *textPreviewViewController;
        if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
            textPreviewViewController = [[ACCRecorderTextModePreviewViewController alloc] initWithTextModel:self.textPublishModel.repoTextMode.textModel backgroundManager:self.backgroundManager];
        } else {
            textPreviewViewController = [[ACCRecorderTextModePreviewViewController alloc] initWithTextModel:self.textPublishModel.repoTextMode.textModel colorManager:self.colorManager];
        }
        self.textPublishModel.repoSticker.recorderInteractionStickers = [[self propViewModel].inputData.publishModel.repoSticker.recorderInteractionStickers copy];
        textPreviewViewController.publishModel = self.textPublishModel;
        textPreviewViewController.layoutGuide = [self viewContainer].layoutManager.guide;
        textPreviewViewController.goNext = ^{
            @strongify(self);
            if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
                [self.backgroundManager savedCurrentBackground];
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.textPublishModel.repoTrack.referExtra];
                params[@"enter_from"] = @"text_edit_page";
                params[@"background_id"] = @(self.backgroundManager.selectedIndex);
                params[@"font"] = self.textPublishModel.repoTextMode.textModel.fontModel.fontName;
                [ACCTracker() trackEvent:@"save_text_detail" params:params];
            }
            [self goNextPage];
        };
        textPreviewViewController.textDidChangeCallback = ^(AWEStoryTextImageModel * _Nullable textModel) {
            @strongify(self);
            self.textPublishModel.repoTextMode.textModel = textModel;
        };
        textPreviewViewController.close = ^{
            @strongify(self);
            [self close];
        };
        textPreviewViewController.textViewDidApear = ^{
            @strongify(self);
            [self.viewModel send_textModeVCDidAppearSignal];
        };
        textPreviewViewController.onBeginEdit = ^(NSString *enterMethod){
            if ([ACCCustomFont() stickerFonts].count == 0) {
                [ACCToast() show:ACCLocalizedCurrentString(@"creation_text_load_fail")];
            }
            @strongify(self);
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.textPublishModel.repoTrack.referExtra];
            referExtra[@"enter_from"] = @"text_edit_page";
            referExtra[@"enter_method"]  = enterMethod ?: @"click_screen";
            referExtra[@"tab_name"]  = @"text";
            [ACCTracker() trackEvent:@"click_text_entrance" params:referExtra needStagingFlag:NO];
        };
        textPreviewViewController.onChangeColor = ^(NSString * _Nonnull colorString) {
            @strongify(self);
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.textPublishModel.repoTrack.referExtra];
            referExtra[@"color_type"] = colorString;
            referExtra[@"tab_name"]  = @"text";
            [ACCTracker() trackEvent:@"change_backgroud_color" params:referExtra needStagingFlag:NO];
        };
        textPreviewViewController.stickerLogger = ({
            @strongify(self);
            ACCStickerLoggerImpl *logger = [[ACCStickerLoggerImpl alloc] init];
            logger.publishModel = self.textPublishModel;
            logger;
        });
        self.textPreviewViewController = textPreviewViewController;
        
        // 写这些代码我的内心是难受的
        self.filterService.panGestureRecognizerEnabled = NO;

        [self.controller.root addChildViewController:self.textPreviewViewController];
        
        self.textPreviewViewController.view.alpha = 0;
        [self.viewContainer.modeSwitchView insertSubview:self.textPreviewViewController.view belowSubview:self.viewContainer.switchModeContainerView];
        [UIView animateWithDuration:0.2 animations:^{
            self.textPreviewViewController.view.alpha = 1;
        }];
        
        [self.textPreviewViewController didMoveToParentViewController:self.controller.root];
        
        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab)) {
            // 确定自己在tab中的位置来决定侧滑方向
            NSInteger tabCount = [self.switchModeService siblingsCountForRecordModeId:ACCRecordModeText];
            NSInteger tabIndex = [self.switchModeService getIndexForRecordModeId:ACCRecordModeText];
            if (tabIndex > 0)
                [self installSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionRight];
            if (tabIndex + 1 < tabCount)
                [self installSwipeGestureRecognizerWithDirection:UISwipeGestureRecognizerDirectionLeft];
        }
        
        if (ACCConfigBool(kConfigBool_text_mode_add_backgrounds)) {
            acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.backgroundManager fetchAllBackgrounds];
            });
        }
    }
}

- (void)installSwipeGestureRecognizerWithDirection:(UISwipeGestureRecognizerDirection)direction
{
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self.submodeViewModel action:@selector(swipeSwitchSubmode:)];
    swipeGesture.direction = direction;
    swipeGesture.numberOfTouchesRequired = 1;
    swipeGesture.delegate = self.submodeViewModel;
    RAC(swipeGesture, enabled) = RACObserve(self.submodeViewModel, swipeGestureEnabled);
    [self.textPreviewViewController.view addGestureRecognizer:swipeGesture];
}

- (void)exitTextMode
{
    [self.textPreviewViewController willMoveToParentViewController:nil];
    [self.textPreviewViewController.view removeFromSuperview];
    [self.textPreviewViewController removeFromParentViewController];
    self.textPreviewViewController = nil;
    if (![self.propViewModel.currentSticker isTypeAR] && ![self.propViewModel.currentSticker isTypeTouchGes]) {
        if (!(ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab))) {
            self.filterService.panGestureRecognizerEnabled = YES;
        }
    }
    BOOL hideExceptToolBar = (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive);
    [self.viewContainer showItems:!hideExceptToolBar animated:NO];
}

- (void)goNextPage
{
    // 问题：文字模式有自己的publishModel（和快拍等拍摄模式的publishModel不是同一个），所以进入编辑页时需要同步
    // 正确做法：添加subscirbers的实现，告诉所有subscirbers即将通过文字模式进入编辑页，此时应该同步publishModel里的信息
    self.textPublishModel.repoSticker.recorderInteractionStickers = [self propViewModel].inputData.publishModel.repoSticker.recorderInteractionStickers;
    
    self.templateManager = IESAutoInline(self.serviceProvider, ACCMVTemplateManagerProtocol);
    self.templateManager.publishModel = self.textPublishModel;
    @weakify(self);
    UIImage *textPreviewImage = [self.textPreviewViewController generateBackgroundImage];
    self.textPublishModel.repoPublishConfig.firstFrameImage = textPreviewImage;
    [self.templateManager exportTextVideoWithImage:textPreviewImage failedBlock:^{
        [ACCToast() showError:ACCLocalizedString(@"com_mig_there_was_a_problem_with_the_internet_connection_try_again_later_yq455g", @"There was a problem with the internet connection. Try again later.")];
        @strongify(self);
        self.templateManager = nil;
    } successBlock:^{
        @strongify(self);
        self.templateManager = nil;
    }];
}

- (void)close
{
    if ([self.textPublishModel.repoTrack.referString isEqualToString:@"text_diary"]) {
        [ACCTracker() trackEvent:@"close_video_shoot_page" params:@{
            @"enter_method" : @"click_button",
            @"shoot_way" : self.textPublishModel.repoTrack.referString ?: @"",
            @"enter_from" : [self propViewModel].inputData.publishModel.repoTrack.enterFrom ?: @"",
            @"publish_cnt" : @([ACCVideoPublish() publishTaskCount]),
            @"prop_panel_open" : @"0",
        }];
    }
    
    [ACCDraft() deleteDraftWithID:[self propViewModel].inputData.publishModel.repoDraft.taskID];
    [self.controller close];
}

- (AWEVideoPublishViewModel *)textPublishModel
{
    if (!_textPublishModel) {
        _textPublishModel = [[self propViewModel].inputData.publishModel copy];
        _textPublishModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryDaTextMode;
        _textPublishModel.repoSticker.shootSameStickerModels = [self propViewModel].inputData.publishModel.repoSticker.shootSameStickerModels;
        _textPublishModel.repoFlowControl.videoRecordButtonType = AWEVideoRecordButtonTypeText;
        _textPublishModel.repoContext.videoType = AWEVideoTypePhotoToVideo; // 主题模板类型
        _textPublishModel.repoContext.feedType = ACCFeedTypeCanvasPost;
        _textPublishModel.repoContext.videoSource = AWEVideoSourceAlbum;
        _textPublishModel.repoTrack.enterFrom = @"text_edit_page";
        _textPublishModel.repoTextMode.isTextMode = YES;
    }
    return _textPublishModel;
}

- (ACCPropViewModel *)propViewModel
{
    return [self getViewModel:[ACCPropViewModel class]];
}

- (ACCRecordTextModeColorManager *)colorManager
{
    if (_colorManager == nil) {
        _colorManager = [[ACCRecordTextModeColorManager alloc] init];
        [_colorManager loadCache];
    }
    return _colorManager;
}

- (NSObject<ACCRecorderBackgroundSwitcherProtocol> *)backgroundManager
{
    if (!_backgroundManager) {
        _backgroundManager = [IESAutoInline(ACCBaseServiceProvider(), ACCRecorderBackgroundManagerProtocol) getACCBackgroundSwitcherWith:ACCBackgroundSwitcherSceneTextMode];
    }
    return _backgroundManager;
}

- (ACCRecordSubmodeViewModel *)submodeViewModel
{
    return [self getViewModel:[ACCRecordSubmodeViewModel class]];
}

- (ACCRecorderTextModeViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCRecorderTextModeViewModel.class];
    }
    return _viewModel;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    BOOL needSilentReleaseTextVC = (oldMode.modeId == ACCRecordModeText) && (mode.modeId == ACCRecordModeAudio);
    if (mode.modeId == ACCRecordModeText) {
        [self enterTextMode];
    } else {
        if (!needSilentReleaseTextVC && self.textPreviewViewController != nil) {
            [self exitTextMode];
        }
    }
}

- (void)silentReleaseTextModeVC
{
    if (self.textPreviewViewController == nil ||
        self.switchModeService.currentRecordMode.modeId == ACCRecordModeText) {
        return;
    }
    [UIApplication.sharedApplication beginIgnoringInteractionEvents];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self exitTextMode];
        [UIApplication.sharedApplication endIgnoringInteractionEvents];
    });
}

@end
