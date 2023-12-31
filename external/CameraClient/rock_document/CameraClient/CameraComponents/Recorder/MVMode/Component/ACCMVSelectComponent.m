//
//  ACCMVSelectComponent.m
//  Pods
//
//  Created by lixingpeng on 2019/8/5.
//

#import "ACCMVSelectComponent.h"
#import <CameraClient/ACCTransitioningDelegateProtocol.h>
#import <CameraClient/ACCAlbumInputData.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CameraClient/ACCEditVideoDataConsumer.h>
// sinkage
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCViewControllerProtocol.h"
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCMVTemplatesTabViewController.h"
#import "ACCMVTemplatesPreloadDataManager.h"
#import "AWEMVTemplateModel.h"
#import "ACCMVCategoryModel.h"
#import "ACCCutSameProtocol.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "ACCConfigKeyDefines.h"
#import "ACCChallengeNetServiceProtocol.h"
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "ACCMVSelectViewModel.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordSubmodeViewModel.h"
#import "ACCRecordSelectMusicService.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoMVModel.h"
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "ACCRepoUserIncentiveModelProtocol.h"
#import <CameraClientModel/AWEVideoRecordButtonType.h>

@interface ACCMVSelectComponent () <AWEMVTemplateModelDelegate, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol> transitionDelegate;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;
// mv进入方式enter_method:
// reminder(引导框)，change_mode(切换拍摄模式tab)，mv_reuse(主题拍同款)
@property (nonatomic, copy, nullable) NSString *mvEnterMethod;

@property (nonatomic, assign) BOOL retryEnterAfterExitFinished; // AME-43312bugfix, 进入的时候还没有销毁完成, 导致打开mv失败
@property (nonatomic, assign) BOOL isFirstAppear;

@property (nonatomic, strong) AWEVideoPublishViewModel *mvPublishModel;
@property (nonatomic, strong) ACCRecordSubmodeViewModel *submodeViewModel;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordSelectMusicService> musicService;
@property (nonatomic, strong) id<ACCFilterService> filterService;

@property (nonatomic, strong) UIViewController *mvTemplateViewController;
@property (nonatomic, strong) ACCMVSelectViewModel *viewModel;

@end

@implementation ACCMVSelectComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, musicService, ACCRecordSelectMusicService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)

// 进入新照片电影模式
- (void)enterMVMode
{
    if (self.mvTemplateViewController) {
        self.retryEnterAfterExitFinished = YES;
        
        return;
    }
    
    self.retryEnterAfterExitFinished = NO;
    
    /**
     * todo: The self.viewModel.inputData.publishModel should be copied and applied to the mvTemplateViewController instance, this class currently uses this model for track service.
     */
    
    if (self.viewContainer.switchModeContainerView) {
        // 进入mv埋点
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"enter_method"] = self.mvEnterMethod ?: @"change_mode";
        params[@"creation_id"] = self.mvPublishModel.repoContext.createId ?: @"";
        params[@"content_type"] = @"mv";
        params[@"content_source"] = @"upload";
        params[@"shoot_way"] = self.mvPublishModel.repoTrack.referString ?: @"";
        if (!ACC_isEmptyString(self.viewModel.inputData.sameMVTemplateModel.effectIdentifier)) {
            params[@"mv_id"] = self.viewModel.inputData.sameMVTemplateModel.effectIdentifier;
        }
        [ACCTracker() trackEvent:@"enter_mv_shoot_page" params:params needStagingFlag:NO];
        self.mvEnterMethod = nil;
        
        // 计算录制按钮的frame
        // 此处需要用录制按钮的frame做形变动画
        const CGFloat kRecordButtonWidth = 80.0f;
        const CGFloat kRecordButtonHeight = 80.0f;
        const CGRect recordButtonFrame = CGRectMake((ACC_SCREEN_WIDTH - kRecordButtonWidth)/2.0f,
                                                    (ACC_SCREEN_HEIGHT - kRecordButtonHeight) + [self.viewContainer.layoutManager.guide recordButtonBottomOffset],
                                                    kRecordButtonWidth,
                                                    kRecordButtonHeight);
        self.mvTemplateViewController = [self mvTemplateViewControllerWithRecordBtnFrame:recordButtonFrame];
        
        [self.rootVC addChildViewController:self.mvTemplateViewController];
        AWERecoderHintsDismissOptions option = (AWERecoderHintsDismissFilterHint |
                                                AWERecoderHintsDismissPropHint |
                                                AWERecoderHintsDismissMusicBubble |
                                                AWERecoderHintsDismissPropMusicBubble);
        [[AWERecorderTipsAndBubbleManager shareInstance] dismissWithOptions:option];
        [self.viewContainer.modeSwitchView insertSubview:self.mvTemplateViewController.view belowSubview:self.viewContainer.switchModeContainerView];
        
        self.filterService.panGestureRecognizerEnabled = NO;
        self.submodeViewModel.swipeGestureEnabled = NO;

        [self.mvTemplateViewController didMoveToParentViewController:self.rootVC];
        [self.viewContainer showItems:NO animated:NO];
    }
}

// 退出新照片电影模式
- (void)exitMVModeHiddenSelectButton:(BOOL)hiddenSelectButton
{
    self.retryEnterAfterExitFinished = NO;
    /*
     * todo: Clear copy publishViewModel data, can be arranged to clear up. @zhangchengtao
     */
    if (!self.mvTemplateViewController) {
        return;
    }
    
    [self p_exitWaterfallMVTemplateMode];
}

- (UIViewController *)mvTemplateViewControllerWithRecordBtnFrame:(CGRect)recordBtnFrame
{
    if (!_mvTemplateViewController) {
        _mvTemplateViewController = [self waterfallMVTemplateVC];
    }
    return _mvTemplateViewController;
}

- (UIViewController *)waterfallMVTemplateVC
{
    [AWEMVTemplateModel sharedManager].delegate = self;
    @weakify(self);
    dispatch_block_t closeBlock = ^{
        @strongify(self);
        [self p_close];
    };
    dispatch_block_t willEnterDetailVCBlock = ^{
        @strongify(self);
        self.viewContainer.switchModeContainerView.hidden = YES;
        self.viewContainer.isShowingMVDetailVC = YES;
    };
    dispatch_block_t didAppearBlock = ^{
        @strongify(self);
        self.viewContainer.switchModeContainerView.hidden = NO;
        self.viewContainer.isShowingMVDetailVC = NO;
    };
    UIViewController<ACCMVWaterfallViewControllerProtocol> *mvtemplateVC;
    mvtemplateVC = [[ACCMVTemplatesTabViewController alloc] init];

    mvtemplateVC.publishViewModel = self.mvPublishModel;
    mvtemplateVC.closeBlock = closeBlock;
    mvtemplateVC.willEnterDetailVCBlock = willEnterDetailVCBlock;
    mvtemplateVC.didAppearBlock = didAppearBlock;
    mvtemplateVC.didPickTemplateBlock = ^(id<ACCMVTemplateModelProtocol> _Nonnull templateModel) {
        @strongify(self);
        if (templateModel.accTemplateType == ACCMVTemplateTypeClassic) {
            IESEffectModel *mv = templateModel.effectModel;
            [AWEMVTemplateModel addEffectModelToManagerIfNeeds:mv];
            
            void (^templateWorkBlock)(void) = ^{
                @strongify(self);
                if (mv.downloaded) {
                    [self p_enterClassicalMVPhotoSelectVC:mv];
                } else {
                    [[AWEMVTemplateModel sharedManager] downloadMaterialForModel:mv];
                }
            };

            if (mv.needServerExcute && [mv.effectIdentifier length] > 0) {
                BOOL legalHintedAgree = [ACCCache() boolForKey:mv.effectIdentifier];
                if (!legalHintedAgree) {
                    NSString *creationID = self.mvPublishModel.repoContext.createId;
                    [ACCAlert() showAlertWithTitle:ACCLocalizedCurrentString(@"tip")
                                          description:ACCLocalizedString(@"Pic_video_hint", @"为获得更优质的效果，需上传至云端处理，处理完成后云端不进行保存。")
                                                image:nil
                                    actionButtonTitle:ACCLocalizedCurrentString(@"agree")
                                    cancelButtonTitle:ACCLocalizedCurrentString(@"cancel")
                                          actionBlock:^{
                        [ACCCache() setBool:YES forKey:mv.effectIdentifier];
                        templateWorkBlock();
                        NSMutableDictionary *params = [@{
                            @"click_type": @"continue"
                        } mutableCopy];
                        params[@"creation_id"] = creationID;
                        [ACCTracker() trackEvent:@"click_mv_cloud_processing_popup" params:params];
                    } cancelBlock:^{
                        NSMutableDictionary *params = [@{
                            @"click_type": @"cancel"
                        } mutableCopy];
                        params[@"creation_id"] = creationID;
                        [ACCTracker() trackEvent:@"click_mv_cloud_processing_popup" params:params];
                    }];
                }else{
                    templateWorkBlock();
                }
            } else {
                templateWorkBlock();
            }
        } else {
            [self p_updatePublishModelWithCutSameTemplateMode:templateModel];
            [self showCutSameImportViewController:templateModel];
        }
    };
    
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:mvtemplateVC];
    
    return navigationVC;
}

- (void)p_updatePublishModelWithClassicalMVTemplate:(IESEffectModel *)templateModel
{
    AWEVideoPublishViewModel *publishModel = self.mvPublishModel;
    // Configure mv related properties to the ccopied publishModel
    publishModel.repoContext.videoType = AWEVideoTypeMV; // 主题模板类型
    publishModel.repoContext.feedType = ACCFeedTypeMV;
    publishModel.repoContext.videoSource = AWEVideoSourceAlbum;
    publishModel.repoMV.templateModelId = templateModel.effectIdentifier;
    publishModel.repoMV.templateModelTip = templateModel.hintLabel;
    publishModel.repoMV.templateMaxMaterial = [[AWEMVTemplateModel sharedManager] templateMaxMaterialForModel:templateModel];
    publishModel.repoMV.templateMinMaterial = [[AWEMVTemplateModel sharedManager] templateMinMaterialForModel:templateModel];
    publishModel.repoMV.templateMusicId = templateModel.musicIDs.firstObject;
    publishModel.repoMV.mvTemplateType = [[AWEMVTemplateModel sharedManager] templateTypeForModel:templateModel];
    publishModel.repoCutSame.accTemplateType = ACCMVTemplateTypeClassic;

    [publishModel setExtensionModelByClass:[self.viewModel.inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)]];
}

- (void)p_updatePublishModelWithCutSameTemplateMode:(id<ACCMVTemplateModelProtocol>)templateModel
{
    if (self.mvPublishModel.repoMusic.music) {
        [self.musicService handleCancelMusic:self.mvPublishModel.repoMusic.music];
        self.mvPublishModel = self.viewModel.inputData.publishModel.copy;
    }
    AWEVideoPublishViewModel *publishModel = self.mvPublishModel;
    // Configure mv related properties to the ccopied publishModel
    publishModel.repoContext.videoType = AWEVideoTypeMV;
    publishModel.repoContext.feedType = ACCFeedTypeMV;
    publishModel.repoContext.videoSource = AWEVideoSourceAlbum;
    publishModel.repoMV.templateModelId = [NSString stringWithFormat:@"%lld", (long long)templateModel.templateID];
    publishModel.repoMV.templateMusicId = templateModel.music.musicID;
    publishModel.repoCutSame.accTemplateType = ACCMVTemplateTypeCutSame;

    [publishModel setExtensionModelByClass:[self.viewModel.inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)]];
}


- (void)p_exitWaterfallMVTemplateMode
{
    [self p_resetPublishModel:self.viewModel.inputData.publishModel];
    [self p_exitMVMode];
}

- (void)p_resetPublishModel:(AWEVideoPublishViewModel *)publishViewModel
{
    // 退出mv模式清理mv信息
    BOOL needResetMusic = NO;
    if ([publishViewModel.repoMusic.music.musicID isEqualToString:publishViewModel.repoMV.templateMusicId]) {
        needResetMusic = YES;
    }
    publishViewModel.repoContext.videoType = AWEVideoTypeNormal;
    publishViewModel.repoContext.feedType = ACCFeedTypeGeneral;
    publishViewModel.repoMV.templateModelId = nil;
    publishViewModel.repoMV.templateModelTip = nil;
    publishViewModel.repoMV.templateMaxMaterial = 0;
    publishViewModel.repoMV.templateMinMaterial = 0;
    publishViewModel.repoMV.templateMusicId = nil;
    publishViewModel.repoMV.templateMusicFileName = nil;
    publishViewModel.repoMV.templateMaterials = nil;
    publishViewModel.repoMV.mvModel = nil;
    publishViewModel.repoCutSame.cutSameEditedTexts = nil;
    publishViewModel.repoCutSame.accTemplateType = ACCMVTemplateTypeUnknow;
    
    if (needResetMusic) {
        [self.musicService cancelForceBindMusic:publishViewModel.repoMusic.music];
    }
}

- (void)p_exitMVMode
{
    self.mvTemplateViewController.view.accessibilityViewIsModal = NO;
    [self.mvTemplateViewController willMoveToParentViewController:nil];
    [self.mvTemplateViewController.view removeFromSuperview];
    [self.mvTemplateViewController removeFromParentViewController];
    if ([self.mvTemplateViewController isKindOfClass:UINavigationController.class]) {
        [(UINavigationController *)self.mvTemplateViewController setViewControllers:@[]];
    }
    self.mvTemplateViewController = nil;
    if (![self.propViewModel.currentSticker isTypeAR] && ![self.propViewModel.currentSticker isTypeTouchGes]) {

        if (ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && ACCConfigBool(kConfigBool_horizontal_scroll_change_subtab)) {
            self.submodeViewModel.swipeGestureEnabled = YES;
            self.filterService.panGestureRecognizerEnabled = NO;
        } else {
            self.filterService.panGestureRecognizerEnabled = YES;
        }

    }
    BOOL hideExceptToolBar = (self.switchModeService.currentRecordMode.modeId == ACCRecordModeLive);
    [self.viewContainer showItems:!hideExceptToolBar animated:NO];
    
    if (self.retryEnterAfterExitFinished) {
        [self enterMVMode];
    }
}

- (void)p_fetchChallengeForEffectModel:(IESEffectModel *)effectModel
{
    // mv挑战
    NSString *effectIdentifier = effectModel.effectIdentifier;
    if (effectModel.challengeIDs.count > 0) {
        
        for (NSString *challengeID in [effectModel.challengeIDs copy]) {
            if (effectIdentifier.length > 0 && challengeID.length > 0) {
                [IESAutoInline(self.serviceProvider, ACCChallengeNetServiceProtocol) requestChallengeItemWithID:challengeID
                                                                                                     completion:^(id<ACCChallengeModelProtocol> _Nullable model, NSError * _Nullable error) {
                    if (error) {
                        AWELogToolError(AWELogToolTagNone, @"p_fetchChallengeForEffectModel failed, error=%@", error);
                    }
                    NSString *challengeName = model.challengeName;
                    if (challengeName.length > 0) {
                        [[AWEMVTemplateModel sharedManager] addMVChallengeArray:@[model] mvEffectId:effectIdentifier];
                    }
                }];
            }
        }
    }
}

- (void)p_enterClassicalMVPhotoSelectVC:(IESEffectModel *)mv
{
    [self p_fetchChallengeForEffectModel:mv];
    [self p_updatePublishModelWithClassicalMVTemplate:mv];
    [self showSelectPhotoViewController:mv];
}

- (void)p_close
{
    [ACCDraft() deleteDraftWithID:self.viewModel.inputData.publishModel.repoDraft.taskID];
    [self.controller close];
}

- (ACCMVSelectViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCMVSelectViewModel.class];
    }
    return _viewModel;
}

#pragma mark - ACCComponentProtocol

- (void)componentDidMount
{
    self.isFirstAppear = YES;
}

- (void)componentWillAppear
{
    if (self.isFirstAppear && self.viewModel.inputData.sameMVTemplateModel) {
        NSInteger photoMovieIndex = [self.switchModeService getIndexForRecordModeId:ACCRecordModeMV];
        if (photoMovieIndex != NSNotFound) {
            // 从拍同款影集进入，直接进入主题模板tab
            self.mvEnterMethod = @"mv_reuse"; // 拍同款进入mv埋点
            [self.viewContainer.switchModeContainerView selectItemAtIndex:photoMovieIndex animated:NO];
        }
    }
    self.isFirstAppear = NO;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - getter

- (UIViewController *)rootVC
{
    return self.controller.root;
}


- (AWEVideoPublishViewModel *)mvPublishModel
{
    if (!_mvPublishModel) {
        _mvPublishModel = self.viewModel.inputData.publishModel.copy;
        _mvPublishModel.repoFlowControl.videoRecordButtonType = AWEVideoRecordButtonTypeUnknown;
    }
    return _mvPublishModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.cameraService addSubscriber:self];
}

#pragma mark - Photo VC
- (void)showSelectPhotoViewController:(IESEffectModel *)effectModel {
    [self showSelectPhotoViewController:effectModel withRequestAuthorCompletionBlock:nil];
}

- (void)showSelectPhotoViewController:(IESEffectModel *)effectModel withRequestAuthorCompletionBlock:(void(^)(void))requestAuthorCompletionBlock
{
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        [self p_presentSelectPhotoViewController:effectModel];
    } else {
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
            if (success) {
                [self p_presentSelectPhotoViewController:effectModel];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedCurrentString(@"tip") message: ACCLocalizedCurrentString(@"com_mig_failed_to_access_photos_please_go_to_the_settings_to_enable_access") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    ACCBLOCK_INVOKE(requestAuthorCompletionBlock);
                }]];
                [ACCAlert() showAlertController:alertController animated:YES];
            }
        }];
    }
}

- (void)p_presentSelectPhotoViewController:(IESEffectModel *)effectModel
{
    ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
    /**
    * todo: The self.viewModel.inputData.publishModel should be copied and applied to the inputData instance, this class currently uses this model for processing the pictures.
    */
    inputData.originUploadPublishModel = self.mvPublishModel;
    UIViewController *selectMusicViewController = nil;
    // TODO
    id<ACCMVTemplateModelProtocol> templateModel = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createMVTemplateWithEffectModel:effectModel urlPrefix:nil];
    
    templateModel.extraModel = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createCutSameTemplateModelWithEffect:effectModel isVideoAndPicMixed:NO];
    templateModel.fragmentCount = [templateModel.extraModel.fragments count];
   
    
    inputData.originUploadPublishModel.repoCutSame.templateModel = templateModel;
    inputData.vcType = ACCAlbumVCTypeForMV;
    @weakify(self);
    inputData.dismissBlock = ^{
        @strongify(self);
        [ACCEditVideoDataConsumer setCacheDirPath:[AWEDraftUtils generateDraftFolderFromTaskId:self.viewModel.inputData.publishModel.repoDraft.taskID]];
    };
    selectMusicViewController = (UIViewController *)[IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:inputData];
    
    UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:selectMusicViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transitionDelegate;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    [self.transitionDelegate.swipeInteractionController wireToViewController:navigationController.topViewController];
    self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = YES;
    [self.rootVC presentViewController:navigationController animated:YES completion:nil];
}

- (void)showCutSameImportViewController:(id<ACCMVTemplateModelProtocol>)templateModel
{
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        [self p_presentCutSameImportViewController:templateModel];
    } else {
        @weakify(self);
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self p_presentCutSameImportViewController:templateModel];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedCurrentString(@"tip") message: ACCLocalizedCurrentString(@"com_mig_failed_to_access_photos_please_go_to_the_settings_to_enable_access") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
                [ACCAlert() showAlertController:alertController animated:YES];
            }
        }];
    }
}

- (void)p_presentCutSameImportViewController:(id<ACCMVTemplateModelProtocol>)templateModel
{
    BOOL isMVNeedServerExcute = (templateModel.effectModel.needServerExcute && [templateModel.effectModel.effectIdentifier length] > 0) ? YES : NO;
    
    BOOL isCartoonForServerExcute = NO;
    for(id<ACCCutSameFragmentModelProtocol> fragmentModel in templateModel.extraModel.fragments) {
        if (!ACC_isEmptyString(fragmentModel.gameplayAlgorithm)) {
            isCartoonForServerExcute = YES;
            break;
        }
    }
    
    void (^templateWorkBlock)(void) = ^{
        ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
        /**
        * todo: The self.viewModel.inputData.publishModel should be copied and applied to the inputData instance, this class currently uses this model for processing the pictures.
        */
        inputData.originUploadPublishModel = self.mvPublishModel;
        @weakify(self);
        UIViewController *selectMusicViewController = [IESAutoInline(self.serviceProvider, ACCCutSameProtocol) cutSameViewControllerWithTemplateModel:templateModel inputData:inputData dismiss:^{
            @strongify(self);
            [ACCEditVideoDataConsumer setCacheDirPath:[AWEDraftUtils generateDraftFolderFromTaskId:self.viewModel.inputData.publishModel.repoDraft.taskID]];
        }];
        UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:selectMusicViewController];
        navigationController.navigationBar.translucent = NO;
        navigationController.modalPresentationStyle = UIModalPresentationCustom;
        navigationController.transitioningDelegate = self.transitionDelegate;
        navigationController.modalPresentationCapturesStatusBarAppearance = YES;
        [self.transitionDelegate.swipeInteractionController wireToViewController:navigationController.topViewController];
        self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = YES;
        [self.rootVC presentViewController:navigationController animated:YES completion:nil];
    };
    
    BOOL legalHintedAgree = YES;
    NSString *templateID = [NSString stringWithFormat:@"%lu", (unsigned long)templateModel.templateID];
    if (isCartoonForServerExcute) {
        legalHintedAgree = [ACCCache() boolForKey:templateID];
    } else if (isMVNeedServerExcute) {
        legalHintedAgree = [ACCCache() boolForKey:templateModel.effectModel.effectIdentifier];
    }
    if (!legalHintedAgree) {
        NSString *creationID = self.mvPublishModel.repoContext.createId;
        [ACCAlert() showAlertWithTitle:ACCLocalizedCurrentString(@"tip")
                              description:ACCLocalizedString(@"Pic_video_hint", @"为获得更优质的效果，需上传至云端处理，处理完成后云端不进行保存。")
                                    image:nil
                        actionButtonTitle:ACCLocalizedCurrentString(@"agree")
                        cancelButtonTitle:ACCLocalizedCurrentString(@"cancel")
                              actionBlock:^{
            if (isCartoonForServerExcute) {
                [ACCCache() setBool:YES forKey:templateID];
            } else {
                [ACCCache() setBool:YES forKey:templateModel.effectModel.effectIdentifier];
            }
            templateWorkBlock();
            NSDictionary *params = @{@"click_type": @"continue",
                                     @"creation_id": creationID ? : @""};
            [ACCTracker() trackEvent:@"click_mv_cloud_processing_popup" params:params];
        } cancelBlock:^{
            NSDictionary *params = @{@"click_type": @"cancel",
                                     @"creation_id": creationID ? : @""};
            [ACCTracker() trackEvent:@"click_mv_cloud_processing_popup" params:params];
        }];
    } else {
        templateWorkBlock();
    }
}

-(id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transitionDelegate;
}

#pragma mark - AWEMVTemplateModelDelegate

- (void)model:(AWEMVTemplateModel *)model didStartDownloadTemplateModel:(IESEffectModel *)templateModel
{
    self.loadingView = [ACCLoading() showWindowLoadingWithTitle:ACCLocalizedString(@"com_mig_loading_67jy7g", nil) animated:NO];
}


- (void)model:(AWEMVTemplateModel *)model didFinishDownloadTemplateModel:(IESEffectModel *)templateModel
{
    [self.loadingView dismiss];
    [self p_enterClassicalMVPhotoSelectVC:templateModel];
}

- (void)model:(AWEMVTemplateModel *)model didFailDownloadTemplateModel:(IESEffectModel *)templateModel withError:(NSError *)error
{
    [self.loadingView dismiss];
    [ACCToast() showToast: ACCLocalizedString(@"mv_theme_download_error", @"影集下载失败")];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.modeId == ACCRecordModeMV) {
        [self.cameraService.cameraControl stopVideoAndAudioCapture];
        [self enterMVMode];
    } else if (oldMode.modeId == ACCRecordModeMV) {
        [self exitMVModeHiddenSelectButton:(mode.modeId == ACCRecordModeLive)];
    }
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService {
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        @strongify(self);
        [self p_preloadMVTemplatesCategoriesAndHotMVTemplates];
        [[AWEMVTemplateModel sharedManager] prefetchPhotoToVideoTemplates];
    });
}

- (void)p_preloadMVTemplatesCategoriesAndHotMVTemplates
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [[ACCMVTemplatesPreloadDataManager sharedInstance] preloadMVTemplatesCategoriesAndHotMVTemplatesWithCompletion:^(BOOL success, ACCMVCategoryModel * _Nullable landingCategory) {
        NSDictionary *trackInfo = @{
            @"shoot_way" : self.viewModel.inputData.publishModel.repoTrack.referString ?: @"",
            @"creation_id" : self.viewModel.inputData.publishModel.repoContext.createId ?: @"",
            @"status" : success ? @"succeed" : @"failed",
            @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
            @"landing_type" : @"default",
            @"tab_name" : landingCategory.categoryName ?: @"",
        };
        [[ACCMVTemplatesPreloadDataManager sharedInstance] setTrackInfo:trackInfo];
    }];
}

- (ACCRecordSubmodeViewModel *)submodeViewModel
{
    return [self getViewModel:ACCRecordSubmodeViewModel.class];
}

@end


