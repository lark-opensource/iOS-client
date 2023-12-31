//
//  ACCImageAlbumFlowComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/11.
//

#import "ACCImageAlbumFlowComponent.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import <CameraClient/ACCImageAlbumEditInputData.h>
#import "ACCImageAlbumEditTransferProtocol.h"
#import "AWEEditPageProtocol.h"
#import "ACCMVTemplateManagerProtocol.h"
#import "AWEMVTemplateModel.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCVideoEditFlowControlViewModel.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCImageAlbumAssetsExportManagerProtocol.h"
#import "ACCImageAlbumLandingModeManagerProtocol.h"
#import "ACCBubbleProtocol.h"
#import "ACCImageAlbumFlowViewModel.h"
#import "ACCImageAlbumEditorDefine.h"
#import "ACCVideoEditTipsService.h"
#import "ACCImageAlbumEditServiceProtocol.h"
#import "ACCEditVideoDataFactory.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCEditPreviewProtocolD.h"
#import "ACCToolBarItemView.h"
#import "ACCEditBarItemLottieExtraData.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import "ACCDraftProtocol.h"
#import <CameraClient/ACCAPPSettingsProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCImageAlbumEditViewModel.h"
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/ACCAPPSettingsProtocol.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCSmartMovieManagerProtocol.h>
#import <CameraClient/ACCSmartMovieUtils.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import "ACCRepoRedPacketModel.h"
#import "ACCRedPacketAlertProtocol.h"
#import "ACCFlowerCampaignManagerProtocol.h"

const static int kImageAlbumMaxCountOfSwitchGuideBubble = 3;

static NSString *const kACCImageAlbumSwitchGuideCountKey = @"kACCImageAlbumSwitchGuideCountKey";
static NSString *const kACCSwitchFromPhotoVideoToImageAlbumResultKey = @"kACCSwitchFromPhotoVideoToImageAlbumResultKey";
static NSString *const kACCImageAlbumClearBubbleConigKey = @"kACCImageAlbumClearBubbleConigKey";

static NSString *const ACCMonitorImageAlbumTransferDurationMonitorKey = @"aweme_edit_image_album_transfer_duration";

static NSString *const ACCMonitorImageAlbumTransferErrorRateMonitorKey = @"aweme_edit_image_album_transfer_error_rate";

@interface ACCImageAlbumFlowComponent ()

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCMVTemplateManagerProtocol> mvTemplateManager;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, weak) id<ACCImageAlbumEditServiceProtocol> imageEditService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsService;
@property (nonatomic, strong) ACCImageAlbumFlowViewModel *viewModel;

@property (nonatomic, strong) UIView *switchGuideBubble;
@property (nonatomic, assign) BOOL hasShowenBubble;
@property (nonatomic, assign) AWEPublishFlowStep flowStep; // 用于存草稿

@property (nonatomic, weak) id<ACCSmartMovieManagerProtocol> smartMovieManager;
@property (nonatomic, assign) BOOL isLowLevelDeviceReady;
@property (nonatomic, assign) BOOL isSwitching;
@property (nonatomic, assign) BOOL isLowLevelDeviceWaitingForSwitch;

@end

@implementation ACCImageAlbumFlowComponent
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, tipsService, ACCVideoEditTipsService)
IESOptionalInject(self.serviceProvider, imageEditService, ACCImageAlbumEditServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCImageAlbumFlowServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
    self.flowStep = [self publishModel].repoFlowControl.step;
}

#pragma mark - life cycle
- (void)componentDidMount
{
    // 覆盖安装后要重新开始弹气泡，即使切换过
    [self p_resetBubbleForAppVersionUpdated];
    
    // 切视频 / 图片这个功能 也有单独的AB
    // 另外 存草稿只能存当前编辑模式下的草稿，存入草稿后就不能来回切了
    // 原因是当前的草稿能力只能存一份草稿，不能关联存入两份
    if (ACCConfigBool(kConfigBool_enable_images_album_publish) &&
        ACCConfigBool(kConfigBool_images_mvp_enable_edit_switch_to_video) &&
        !self.repository.repoDraft.isDraft &&
        !self.repository.repoDraft.isBackUp &&
        self.repository.repoImageAlbumInfo.transformContext.isImageAlbumTransformContext) {
        
        [self.viewContainer addToolBarBarItem:[self imageAlbumEditBarItem]];
        
        self.hasShowenBubble = [ACCCache() boolForKey:ACCImageAlbumSessionSwitchModeBubbleShowenKey];
        
        if (self.repository.repoImageAlbumInfo.transformContext.didTransformedOnce) {
            // 由于图集/视频的video是同ID 切换后存一次草稿，否则kill APP草稿会串
            [ACCDraft() saveDraftWithPublishViewModel:self.repository video:self.repository.repoVideoInfo.video backup:YES completion:^(BOOL success, NSError * _Nonnull error) {
                AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumFlowComponent : save draft after transforme, result:%@, error:%@",@(success), error);
            }];
        }
    }
    
    [self bindViewModel];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)dealloc
{
    AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumFlowComponent : %s", __func__);
}

- (void)bindViewModel
{
    @weakify(self);
    [self.tipsService.showImageAlbumSwitchModeBubbleSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (![ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
            [[self viewModel] updateIsSwitchModeBubbleAllowed:[self p_shouldShowSwitchBubble]];
            [self p_showSwitchBubbleIfNeeded];
        }
    }];
    
    [self.imageEditService.scrollGuideDidDisappearSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if (![ACCToolBarAdapterUtils useAdaptedToolBarContainer] && !self.flowService.isQuickPublishBubbleShowed) {
            [self p_showSwitchBubbleIfNeeded];
        }
    }];
}

#pragma mark - ACCEditSessionLifeCircleEvent
- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    @weakify(self);
    /// 低端机不停地点切换优化临时优化，相当于做了个延迟处理，避免VE侧问题，后续等VE解决了在删除
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        self.isLowLevelDeviceReady = YES;
        if (self.isLowLevelDeviceWaitingForSwitch) {
            self.isLowLevelDeviceWaitingForSwitch = NO;
            [self p_handleOnSwitchImageVideoBarItemClick];
        }
    });
}

#pragma mark - bar item
- (ACCBarItem<ACCEditBarItemExtraData*>*)imageAlbumEditBarItem
{
    let config = [self barItemResourceConfig];
    if (!config) {
        return nil;
    }
    
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.location = config.location;
    barItem.itemId = [self configIdentifier];
    barItem.type = ACCBarItemFunctionTypeDefault;
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        [self onSwitchImageVideoBarItemClick];
    };
    barItem.needShowBlock = ^BOOL{
        return YES;
    };
    barItem.showBubbleBlock = ^{
        @strongify(self);
        [self p_showSwitchBubbleIfNeeded];
    };
    
    BOOL isLottie = NO;
    NSString *lottieResourceName = @"";
    if ([self p_shouldShowSwitchBubble]) {
        isLottie = config.isLottie;
        lottieResourceName = config.lottieResourceName;
    }
    
    barItem.extraData = [[ACCEditBarItemLottieExtraData alloc] initWithButtonClass:nil
                                                                              type:AWEEditAndPublishViewDataTypeImageVideoSwitch
                                                                          isLottie:isLottie
                                                                lottieResourceName:lottieResourceName];
    
    barItem.barItemViewConfigBlock = ^(UIView * _Nonnull view) {
        if (isLottie && [lottieResourceName hasSuffix:@".json"]) {
            LOTAnimationView *lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(lottieResourceName)];
            CGFloat offset = 18.f;
            lottieView.frame = CGRectMake(-offset / 2.f,
                                          -offset / 2.f,
                                          AWEEditActionItemButtonSideLength + offset,
                                          AWEEditActionItemButtonSideLength + offset);
            [lottieView playWithCompletion:^(BOOL animationFinished) {
                @strongify(self);
                [self p_showSwitchBubble];
            }];
            
            AWEEditActionItemView *itemView = ACCDynamicCast(view, AWEEditActionItemView);
            if (itemView) {
                [itemView updateActionView:lottieView];
            }
        }
    };
    return barItem;
}

- (void *)configIdentifier
{
    return ([self repository].repoImageAlbumInfo.isImageAlbumEdit ?
            ACCEditToolBarImage2VideoContext : ACCEditToolBarVideo2ImageContext);
}

- (ACCBarItemResourceConfig *)barItemResourceConfig
{
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:[self configIdentifier]];
    return config;
}

#pragma mark - Bubble

- (void)p_showSwitchBubbleIfNeeded
{
    if (![self p_shouldShowSwitchBubble]) {
        return;
    }
    
    if ([self p_shouldWaitLottieFinish]) {
        AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:[self configIdentifier]];
        ACCToolBarItemView *toolItemView = ACCDynamicCast(itemView, ACCToolBarItemView);
        if (toolItemView) {
            @weakify(self);
            toolItemView.lottieCompletionBlock = ^(BOOL animationFinished) {
                @strongify(self);
                [self p_showSwitchBubble];
            };
        }
    } else {
        [self p_showSwitchBubble];
    }
}

- (BOOL)p_shouldShowSwitchBubble
{
    NSNumber *activityVideoType = [[self repository] repoContext].activityVideoType;
    if (activityVideoType) {
        return NO;
    }
    
    if ([self repository].repoDraft.isDraft ||
        [self repository].repoDraft.isBackUp ||
        ![self repository].repoImageAlbumInfo.transformContext.isImageAlbumTransformContext) {
        return NO;
    }
    
    /*
     1、第一次进来是照片电影，有日常引导气泡所以不弹，再进来，弹够3次，或者切换了一次图集，就不弹了
     2、第一次进来是图集，有日常引导气泡，点击切换到照片电影，不弹，下次再进来是照片电影，弹够3次，或者切换了一次图集，就不弹了
     */
    BOOL didSwitchFromPhotoVideoToImageAlbumOnce = [ACCCache() boolForKey:kACCSwitchFromPhotoVideoToImageAlbumResultKey];
    BOOL didTransformedOnce = self.repository.repoImageAlbumInfo.transformContext.didTransformedOnce;
    if (didSwitchFromPhotoVideoToImageAlbumOnce || (!didSwitchFromPhotoVideoToImageAlbumOnce && didTransformedOnce)) {
        return NO;
    }    
    
//    if (self.hasShowenBubble) {
//        return NO;
//    }
    
    NSInteger count = [ACCCache() integerForKey:kACCImageAlbumSwitchGuideCountKey];
    if (count >= kImageAlbumMaxCountOfSwitchGuideBubble) {
        return NO;
    }
    
    // 首次安装：先清理，没有引导（不弹），有引导（弹，次数满足要求）
    // 新版本到更新版本：已清理过本次不清理，没有引导（弹），有引导（弹，次数满足要求）
    // 旧版本到新版本：先清理，没有引导（弹），有引导（弹）
    BOOL isAppVersionUpdated = [ACCAPPSettings() isAppVersionUpdated];
    if (![ACCCache() boolForKey:kACCImageAlbumEditDiaryGuideDisappearKey] && !isAppVersionUpdated) {
        return NO;
    }
    
    return YES;
}

- (BOOL)p_shouldWaitLottieFinish {
    if ([self repository].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }
    
    if (![self barItemResourceConfig].isLottie || ![[self barItemResourceConfig].lottieResourceName hasSuffix:@".json"]) {
        return NO;
    }
    
    return YES;
}

- (void)p_showSwitchBubble
{
    let config = [self barItemResourceConfig];
    AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:[self configIdentifier]];
    NSInteger count = [ACCCache() integerForKey:kACCImageAlbumSwitchGuideCountKey];
    NSString *bubbleContent = self.repository.repoImageAlbumInfo.isImageAlbumEdit ? @"点击可切换为照片电影" : @"点击可切换为图集";
    @weakify(self);
    self.switchGuideBubble = [ACCBubble() showBubble:bubbleContent
                                             forView:itemView
                                     inContainerView:self.viewContainer.containerView
                                    anchorAdjustment:CGPointMake(0, -5)
                                         inDirection:config.location == ACCBarItemResourceLocationBottom ? ACCBubbleDirectionUp : ACCBubbleDirectionLeft
                                             bgStyle:ACCBubbleBGStyleDefault
                                          completion:^{
        @strongify(self);
        [self p_dismissSwitchBubbleIfDisplaying];
    }];
    
    [ACCCache() setInteger:count + 1 forKey:kACCImageAlbumSwitchGuideCountKey];
    [ACCCache() setBool:YES forKey:ACCImageAlbumSessionSwitchModeBubbleShowenKey];
    self.hasShowenBubble = YES;
   
    NSDictionary *referExtra = self.repository.repoTrack.referExtra;
    [ACCTracker() trackEvent:@"photo_change_popup_show"
                      params:@{
                          @"shoot_way" : self.repository.repoTrack.referString ?: @"",
                          @"creation_id" : self.repository.repoContext.createId ?: @"",
                          @"content_source" : self.repository.repoTrack.contentSource ?: @"",
                          @"content_type" : referExtra[@"content_type"] ?: @"",
                          @"type" : self.repository.repoImageAlbumInfo.isImageAlbumEdit ? @"slideshow" : @"multi_photo",
                      }];
}

- (void)p_dismissSwitchBubbleIfDisplaying
{
    if (self.switchGuideBubble) {
        [ACCBubble() removeBubble:self.switchGuideBubble];
        self.switchGuideBubble = nil;
    }
}

- (void)p_markModeSwitched
{
    [self p_dismissSwitchBubbleIfDisplaying];
    if (self.hasShowenBubble) {
        [ACCCache() setInteger:kImageAlbumMaxCountOfSwitchGuideBubble forKey:kACCImageAlbumSwitchGuideCountKey];
    }
}

- (BOOL)p_imageAlbumV3LottieIconConfig
{
    return [ACCConfigDict(kConfigDict_images_mvp_publish_opt) acc_boolValueForKey:kConfigBool_images_publish_opt_icon_animation];
}

- (void)p_resetBubbleForAppVersionUpdated
{
    // 对于没有添加图集3期优化之Lottie动效逻辑之前的版本，虽然弹了3次气泡，但是新安装本版本之后的版本，会重新清0后再次弹3次（切换过一次图集就不再提示了）
    BOOL hasCleanedBubbleConfig = [ACCCache() boolForKey:kACCImageAlbumClearBubbleConigKey];
    if (!hasCleanedBubbleConfig && [self p_imageAlbumV3LottieIconConfig]) {
        [ACCCache() setInteger:0 forKey:kACCImageAlbumSwitchGuideCountKey];
        [ACCCache() setBool:YES forKey:kACCImageAlbumClearBubbleConigKey];
    }
}

#pragma mark - switch handler

- (void)onSwitchImageVideoBarItemClick
{
    // 视频切换到图集不能发红包，给与提示
    if (!self.repository.repoImageAlbumInfo.isImageAlbumEdit &&
        self.repository.repoRedPacket.didBindRedpacketInfo) {
        
        [ACCFlowerCampaignManager() logFlowerInfo:@"[redpacket][image album]video switch alert show"];
        @weakify(self);
        [ACCRedPacketAlert() showAlertWithTitle:nil description:@"确定切换为图集？图集模式不能使用红包" image:nil actionButtonTitle:@"确定" cancelButtonTitle:@"取消" actionBlock:^{
            @strongify(self);
            // 会截图，所以稍加延迟
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @strongify(self);
                [ACCFlowerCampaignManager() logFlowerInfo:@"[redpacket][image album]video switch alert:user confirm"];
                [self p_doOnSwitchImageVideoBarItemClick];
            });
        } cancelBlock:^{
            [ACCFlowerCampaignManager() logFlowerInfo:@"[redpacket][image album]video switch alert:user cancel"];
        }];
        
    } else {
        [self p_doOnSwitchImageVideoBarItemClick];
    }
}

- (void)p_doOnSwitchImageVideoBarItemClick
{
    if (![self p_isLowLevelDeviceOpt] ||
        self.isLowLevelDeviceReady) {
        
        [self p_handleOnSwitchImageVideoBarItemClick];
    } else {
        // 低端机图集切视频需要在首帧完成之后，否则VE侧有概率会出现问题
        if (!self.isSwitching) {
            [ACCLoading() showWindowLoadingWithTitle:@"加载中..." animated:NO];
        }
        self.isLowLevelDeviceWaitingForSwitch = YES;
    }
}

- (void)p_handleOnSwitchImageVideoBarItemClick
{
    if (self.isSwitching) {
        return;
    }
    
    self.isSwitching = YES;
    
    AWEVideoPublishViewModel *currentPublishModel = self.repository;
    ACCEditViewControllerInputData *currentInputData = [self viewModel].inputData;
    ACCImageAlbumEditInputData *imageAlbumEditInputData = currentInputData.imageAlbumEditInputData;
    BOOL currentIsImageEditMode = currentPublishModel.repoImageAlbumInfo.isImageAlbumEdit;
    
    // 先将当前的编辑页截图放到window上，因为要先释放当前的编辑页VC在延迟加入切换后的编辑页VC
    // 延迟切换的目的是 两个VC同时存在会造成内存峰值会过高
    UIWindow *screenWindow = [UIApplication sharedApplication].delegate.window;
    // 注意这里需要使用acc_snapshotImageAfterScreenUpdates:，因为需要截取VEImage的纹理依赖drawViewHierarchy
    UIImage *screenSnapshotImage = [screenWindow acc_snapshotImageAfterScreenUpdates:NO];
    UIImageView *screenSnapshotImageView = [[UIImageView alloc] initWithFrame:screenWindow.bounds];
    screenSnapshotImageView.image = screenSnapshotImage;
    [screenWindow addSubview:screenSnapshotImageView];
    
    __block AWEVideoPublishViewModel *willTransforToPublishModel = nil;
    // 在转场之前，取出将要切换的publishModel
    if (currentIsImageEditMode) {
        
        willTransforToPublishModel = imageAlbumEditInputData.videoModePublishModel;
        id<ACCEditVideoDataProtocol> videoData = [self fetchVideoDataWhenSmartMovieOpen:willTransforToPublishModel];
        if (videoData) { // 如果数据存在，则直接更新
            [willTransforToPublishModel.repoVideoInfo updateVideoData:videoData];
        }
        
    } else {
        willTransforToPublishModel = imageAlbumEditInputData.imageModePublishModel;
    }
    
    NSString *toast = @"加载中...";
    BOOL isGotoSmartMovie = NO;
    if (currentIsImageEditMode) {
        if ([self isGotoSmartMovieWithModel:willTransforToPublishModel]) {
            toast = @"智能转场效果加载中";
            isGotoSmartMovie = YES;
        } else {
            toast = @"默认效果加载中";
        }
    }
    
    @weakify(self);
    if (isGotoSmartMovie) {
        [[ACCLoading() showWindowLoadingWithTitle:toast animated:YES] showCloseBtn:YES closeBlock:^{
            @strongify(self);
            [self.smartMovieManager cancelExport];
        }];
    } else {
        [ACCLoading() showWindowLoadingWithTitle:toast animated:YES];
    }
    
    void(^switchFinishedHandler)(BOOL, NSString *) = ^(BOOL succeedResult, NSString *errorLogMsgResult) {
        if (!NSThread.isMainThread) {
            NSAssert(NO, @"switchFinishedHandler must work on the main thread");
            AWELogToolError(AWELogToolTagEdit, @"ImageAlbumFlowComponent : thread error:%@, succeed:%@ errorLogMsg:%@, currentIsImageEditMode:%@", NSThread.currentThread, @(succeedResult), errorLogMsgResult, @(currentIsImageEditMode));
        }
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            [ACCLoading() dismissWindowLoadingWithAnimated:YES];
            [self.smartMovieManager prepareToProcessSmartMovie];
            self.isSwitching = NO;
            BOOL succeed = succeedResult;
            NSString *errorLogMsg = errorLogMsgResult;
            if (screenSnapshotImageView == nil) {
                NSAssert(NO, @"screenSnapshotImageView should not be nil, check!!!");
                succeed = NO;
                errorLogMsg = @"screenSnapshotImageView is nil";
            }
            [screenSnapshotImageView removeFromSuperview];
            
            if (!succeed) {
                [ACCToast() show:@"网络不给力，请稍后重试"];
                AWELogToolError(AWELogToolTagEdit, @"ImageAlbumFlowComponent : edit switch faild: %@, currentIsImageEditMode:%@", errorLogMsg, @(currentIsImageEditMode));
            } else {
                AWELogToolInfo(AWELogToolTagEdit, @"ImageAlbumFlowComponent : edit switch succeed, currentIsImageEditMode:%@", @(currentIsImageEditMode));
            }
        });
    };
    
    UIViewController *currentEditPage = self.controller.root;
    
    if (!currentEditPage ||
        ![currentEditPage conformsToProtocol:@protocol(AWEEditPageProtocol)]) {
        /// @warning 未来如果触发此断言说明编辑页的层级结构变了，需要图片编辑这里对应修改
        NSAssert(NO, @"!!! fatal case !!! please check");
        ACCBLOCK_INVOKE(switchFinishedHandler, NO, @"vc hierarchy error, current root page is not AWEEditPage");
        return;
    }

    if (!imageAlbumEditInputData) {
        NSAssert(NO, @"bad case, check");
        ACCBLOCK_INVOKE(switchFinishedHandler, NO, @"no image album edit input data");
        return;
    }
    
    void(^transferHandler)(void) = ^(void) {
        
        @strongify(self);
        
        UINavigationController *navigationController = currentEditPage.navigationController;
        NSMutableArray <UIViewController *> *viewControllers = [NSMutableArray arrayWithArray:navigationController.viewControllers];
        
        if (![viewControllers containsObject:currentEditPage]) {
            /// 未来如果触发此断言说明编辑页的层级结构变了，需要图片编辑这里对应修改
            NSAssert(NO, @"!!! fatal case !!! check");
            ACCBLOCK_INVOKE(switchFinishedHandler, NO, @"navigation hierarchy error, viewControllers did not contain current edit vc");
            return;
        }
        // 更新context，防止递归引用
        if ([ACCSmartMovieABConfig isOn]) {        
            willTransforToPublishModel.repoContext.sourceModel = nil;
        }
        
        [self.flowService notifyWillSwitchImageAlbumEditMode];
        
        id<ACCImageAlbumLandingModeManagerProtocol> landingModeManager = IESAutoInline(ACCBaseServiceProvider(), ACCImageAlbumLandingModeManagerProtocol);

        // 在转场之前，把当前编辑的publishModel缓存起来，下次切换在恢复
        // 因为传入编辑页已经进行过copy 所以会导致不同源 如果不重新赋值，编辑效果会丢失
        if (currentIsImageEditMode) {
            
            if ([self isGotoSmartMovieWithModel:willTransforToPublishModel]) {
                willTransforToPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeSmartMovie;
                [self.smartMovieManager setCurrentScene:ACCSmartMovieSceneModeSmartMovie];
                [landingModeManager.class markUsedSmartMovieMode];
            } else {
                willTransforToPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeMVVideo;
                [self.smartMovieManager setCurrentScene:ACCSmartMovieSceneModeMVVideo];
                [landingModeManager.class markUsedPhotoVideoMode];
            }
            
            imageAlbumEditInputData.imageModePublishModel = [currentPublishModel copy];
            imageAlbumEditInputData.videoModePublishModel = willTransforToPublishModel;
           
        } else {
            
            id<ACCEditVideoDataProtocol> videoData = currentPublishModel.repoVideoInfo.video;
            if ([self.smartMovieManager isMVVideoMode]) {
                currentPublishModel.repoSmartMovie.videoForMV = videoData;
            } else {
                currentPublishModel.repoSmartMovie.videoForSmartMovie = videoData;
            }
            currentPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeImageAlbum;
            willTransforToPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeImageAlbum;
            [self.smartMovieManager setCurrentScene:ACCSmartMovieSceneModeImageAlbum];
            
            imageAlbumEditInputData.imageModePublishModel = willTransforToPublishModel;
            imageAlbumEditInputData.videoModePublishModel = [currentPublishModel copy];

            [landingModeManager.class markUsedImageAlbumMode];
        }
        
        if (![ACCSmartMovieABConfig isOn]) {
            currentPublishModel.repoImageAlbumInfo.transformContext.didHandleImageAlbum2MVVideo = YES;
        }
        
        // 更新数据，为了能保持草稿为当前编辑
        willTransforToPublishModel.repoFlowControl.step = self.flowStep;
        imageAlbumEditInputData.videoModePublishModel.repoFlowControl.step = self.flowStep;
        imageAlbumEditInputData.imageModePublishModel.repoFlowControl.step = self.flowStep;
        
        [self.editService.imageAlbumMixed releasePlayer];
        
        [viewControllers removeObject:currentEditPage];
        navigationController.viewControllers = [viewControllers copy];
        
        // Create a temporary cancelBlock and assign it to the new edit page after the old edit page deallocated
        AWEEditAndPublishCancelBlock tmpCancelBlock = nil;
        if (currentEditPage && [currentEditPage conformsToProtocol:@protocol(AWEEditPageProtocol)]) {
            tmpCancelBlock = [(UIViewController<AWEEditPageProtocol> *)(currentEditPage)  inputData].cancelBlock;
        }
        
        // 延迟切换 避免两个VC同时存在内存峰值过高
        // 理论上下个runloop即可，但是有一些中间纹理数据之类的清理可能并不是立即结束,保守起见加了点延迟
        // 另一种方案是考虑缓存不同编辑模式下的VC，但是内存占用会占用100-200M，性能上考虑采用新建VC走草稿恢复模式
        @weakify(navigationController);
        
        // 低端机可能放开图集，稍微加一些延迟 避免内存问题
        NSTimeInterval delayTime = [self p_isLowLevelDeviceOpt]? 2.0: 0.35;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            /// @warning 这block里面不要再用self，已经释放
            
            // 理论上不需要，保险起见 weak了下navi
            @strongify(navigationController);
            
            if (!navigationController) {
                NSAssert(NO, @"!!! fatal case !!! why? check");
                ACCBLOCK_INVOKE(switchFinishedHandler, NO, @"navigation vc released");
            }
            
            // 一些标记位需要在准备转转场之前拷贝一下
            currentPublishModel.repoImageAlbumInfo.transformContext.didTransformedOnce = YES;
            willTransforToPublishModel.repoImageAlbumInfo.transformContext = [currentPublishModel.repoImageAlbumInfo.transformContext copy];
            
            UIViewController<AWEEditPageProtocol> *willTransforToEditPage = [ACCImageAlbumEditTransfer() videoEditorWithModel:willTransforToPublishModel];
            
            // videoEditorWithModel里面copy了,所以指向一下 防止不同源产生问题
            // 虽然切换后也会重新指向一次，但是提前指向一次防止以后再中间过程用到留坑
            willTransforToPublishModel = willTransforToEditPage.inputData.publishModel ?: willTransforToPublishModel;

            if (currentIsImageEditMode) {
                imageAlbumEditInputData.videoModePublishModel = willTransforToPublishModel;
            } else {
                imageAlbumEditInputData.imageModePublishModel = willTransforToPublishModel;
                [ACCCache() setBool:YES forKey:kACCSwitchFromPhotoVideoToImageAlbumResultKey];
            }
            
            willTransforToEditPage.inputData.imageAlbumEditInputData = [imageAlbumEditInputData copy];
            willTransforToEditPage.inputData.showGuideBubble = YES;
            if (tmpCancelBlock) {
                willTransforToEditPage.inputData.cancelBlock = tmpCancelBlock;
            }
            
            // 切换的埋点用的是切换后的publishmodel的信息
            p_trackTransferWithTargetPublishModel(willTransforToPublishModel);
            
            // 重新取一下 毕竟延迟了防止vc堆栈有问题
            NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:navigationController.viewControllers];
            [viewControllers addObject:willTransforToEditPage];
            navigationController.viewControllers = [viewControllers copy];
            
            ACCBLOCK_INVOKE(switchFinishedHandler, YES, nil);
        });
    };
    
    if ([ACCSmartMovieABConfig isOn]) {
        [self transferWithRepository:willTransforToPublishModel currentRepository:currentPublishModel isImageMode:currentIsImageEditMode constructor:^(AWEVideoPublishViewModel *result) {
            willTransforToPublishModel = [result copy];
        } transfer:transferHandler defer:switchFinishedHandler];
    } else {
        [self transferWithoutSmartMovieByRepository:willTransforToPublishModel currentRepository:currentPublishModel isImageMode:currentIsImageEditMode constructor:^(AWEVideoPublishViewModel *result) {
            willTransforToPublishModel = [result copy];
        } transfer:transferHandler defer:switchFinishedHandler];
    }
    
    [self p_markModeSwitched];
}

- (void)transferWithRepository:(AWEVideoPublishViewModel *)willTransforToPublishModel
             currentRepository:(AWEVideoPublishViewModel *)currentPublishModel
                   isImageMode:(BOOL)isImageMode
                   constructor:(void(^)(AWEVideoPublishViewModel *result))constructor                      transfer:(void(^)(void))transferBlock
                         defer:(void(^)(BOOL succeed, NSString *errorMsg))deferBlock
{
    if (isImageMode) {
    // 去视频场景
        NSInteger totalCount = [self.editService.imageAlbumMixed totalImagePlayerImageCount];
        
        if ([self isGotoSmartMovieWithModel:willTransforToPublishModel]) {
            
            if (self.smartMovieManager.sceneDataMarker.smartMovieDataExist && [currentPublishModel.repoMusic.music.musicID isEqualToString:willTransforToPublishModel.repoSmartMovie.musicForSmartMovie.musicID]) {
                [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:NO];
                ACCBLOCK_INVOKE(transferBlock);
            } else {
                @weakify(self);
                id<ACCMusicModelProtocol> musicModel = currentPublishModel.repoMusic.music;
                // 替换音乐
                willTransforToPublishModel.repoMusic.music = musicModel;
                willTransforToPublishModel.repoMusic.bgmAsset = [AVAsset assetWithURL:musicModel.loaclAssetUrl];
                [self exportSmartMovieWithPublishModel:willTransforToPublishModel
                                               musicID:musicModel.musicID
                                          succeedBlock:^(BOOL isCanceled,
                                                         AWEVideoPublishViewModel *result) {
                    @strongify(self);
                    if (isCanceled) {
                        self.smartMovieManager.sceneDataMarker.smartMovieDataExist = NO;
                        ACCBLOCK_INVOKE(deferBlock, YES, ACCSmartMovieExportCancelByUserKey);
                    } else {
                        self.smartMovieManager.sceneDataMarker.smartMovieDataExist = YES;
                        [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:NO];
                        
                        constructor(result);
                        
                        id<ACCEditVideoDataProtocol> videoData = result.repoVideoInfo.video;
                        willTransforToPublishModel.repoSmartMovie.videoForSmartMovie = videoData;
                        
                        ACCBLOCK_INVOKE(transferBlock);
                    }
                } failedBlock:^{
                    @strongify(self);
                    [self p_monitorForSwithMode:NO totalCount:totalCount isToImageAlbum:NO];
                    ACCBLOCK_INVOKE(deferBlock, NO, @"SmartMovie: export smart movie when switch scene faild");
                }];
            }
        } else {
            // 首次图片切视频需要先合成MV视频
            if (!self.smartMovieManager.sceneDataMarker.mvDataExist || (![currentPublishModel.repoMusic.music.musicID isEqualToString:currentPublishModel.repoSmartMovie.musicForMV.musicID])) {
                // 产品要求第一次切换生成视频的时候共用一个music，用户有可能切换过音乐，所以需要覆盖外面选的歌曲
                // 从相册进入编辑页默认是图集时，切换了音乐再取消后（currentPublishModel.repoMusic.music == nil），照片电影依然用默认的音乐
                id<ACCMusicModelProtocol> imageAlbumMusic = currentPublishModel.repoMusic.music ?: [AWEMVTemplateModel.sharedManager videoMusicModelWithType:AWEPhotoToVideoPhotoCountTypeNone];
                if (imageAlbumMusic) {
                    willTransforToPublishModel.repoMusic.music = imageAlbumMusic;
                    willTransforToPublishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceImageAlbumEditSwitched;
                }
                
                [ACCMonitor() startTimingForKey:ACCMonitorImageAlbumTransferDurationMonitorKey];
                NSInteger totalCount = [self.editService.imageAlbumMixed totalImagePlayerImageCount];
                @weakify(self)
                [self exportMVVideoWithPublishModel:willTransforToPublishModel
                                            succeed:^(AWEVideoPublishViewModel *result) {
                    @strongify(self)
                    self.smartMovieManager.sceneDataMarker.mvDataExist = YES;
                    [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:NO];
                    
                    constructor(result);
                    
                    if (acc_isOpenSmartMovieCapabilities(willTransforToPublishModel)) {
                        id<ACCEditVideoDataProtocol> videoData = result.repoVideoInfo.video;
                        willTransforToPublishModel.repoSmartMovie.videoForMV = videoData;
                    }
                    
                    ACCBLOCK_INVOKE(transferBlock);
                    
                } failed:^{
                    @strongify(self)
                    [self p_monitorForSwithMode:NO totalCount:totalCount isToImageAlbum:NO];
                    ACCBLOCK_INVOKE(deferBlock, NO, @"export MV Video faild");
                }];
            } else {
                ACCBLOCK_INVOKE(transferBlock);
            }
        }
    } else {
        // 去图集场景
        self.smartMovieManager.previousScene = [self.smartMovieManager isMVVideoMode] ? ACCSmartMovieSceneModeMVVideo : ACCSmartMovieSceneModeSmartMovie;
        if (!willTransforToPublishModel.repoImageAlbumInfo.imageAlbumData) {
            // 首次从照片电影切换到图集
            self.smartMovieManager.sceneDataMarker.imageAlbumDataExist = YES;
            [ACCMonitor() startTimingForKey:ACCMonitorImageAlbumTransferDurationMonitorKey];
            NSInteger totalCount = [self publishModel].repoUploadInfo.selectedUploadAssets.count;
            @weakify(self);
            [self exportImageAlbumWithPublishModel:willTransforToPublishModel
                                           succeed:^(AWEVideoPublishViewModel *result) {
                @strongify(self);
                [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:YES];
                
                if (currentPublishModel.repoMusic.music) {
                    willTransforToPublishModel.repoMusic.music = currentPublishModel.repoMusic.music;
                    willTransforToPublishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceImageAlbumEditSwitched;
                    if ([ACCSmartMovieABConfig isOn] && [self.smartMovieManager isMVVideoMode]) {
                        willTransforToPublishModel.repoSmartMovie.musicForMV = currentPublishModel.repoMusic.music;
                    } else {
                        willTransforToPublishModel.repoSmartMovie.musicForSmartMovie = currentPublishModel.repoMusic.music;
                    }
                }
                // 视频模式下切换到图片之前先更新视频，特别是贴纸
                [self updateDataVideoWithCompleteBlock:^{
                    ACCBLOCK_INVOKE(transferBlock);
                }];
            } failed:^{
                @strongify(self);
                [self p_monitorForSwithMode:NO totalCount:totalCount isToImageAlbum:YES];
                ACCBLOCK_INVOKE(deferBlock, NO, @"export image album faild");
            }];
        } else {
            // 视频模式下切换到图片之前先更新视频，特别是贴纸
            [self updateDataVideoWithCompleteBlock:^{
                id<ACCMusicModelProtocol> targetMusic = currentPublishModel.repoMusic.music;
                if (![willTransforToPublishModel.repoMusic.music.musicID isEqualToString:targetMusic.musicID]) {
                    willTransforToPublishModel.repoMusic.music = targetMusic;
                    willTransforToPublishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceImageAlbumEditSwitched;
                }
                ACCBLOCK_INVOKE(transferBlock);
            }];
        }
    }
}


- (void)transferWithoutSmartMovieByRepository:(AWEVideoPublishViewModel *)willTransforToPublishModel
                            currentRepository:(AWEVideoPublishViewModel *)currentPublishModel
                                  isImageMode:(BOOL)isImageMode
                                  constructor:(void(^)(AWEVideoPublishViewModel *result))constructor
                                     transfer:(void(^)(void))transferHandler
                                        defer:(void(^)(BOOL succeed, NSString *errorMsg))deferBlock
{
    
    if (isImageMode) {
        // 首次图片切视频需要先合成MV视频
        if (!currentPublishModel.repoImageAlbumInfo.transformContext.didHandleImageAlbum2MVVideo) {
            // 产品要求第一次切换生成视频的时候共用一个music，用户有可能切换过音乐，所以需要覆盖外面选的歌曲
            // 从相册进入编辑页默认是图集时，切换了音乐再取消后（currentPublishModel.repoMusic.music == nil），照片电影依然用默认的音乐
            id<ACCMusicModelProtocol> imageAlbumMusic = currentPublishModel.repoMusic.music ?: [AWEMVTemplateModel.sharedManager videoMusicModelWithType:AWEPhotoToVideoPhotoCountTypeNone];
            if (imageAlbumMusic) {
                willTransforToPublishModel.repoMusic.music = imageAlbumMusic;
                willTransforToPublishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceImageAlbumEditSwitched;
            }
            
            [ACCMonitor() startTimingForKey:ACCMonitorImageAlbumTransferDurationMonitorKey];
            NSInteger totalCount = [self.editService.imageAlbumMixed totalImagePlayerImageCount];
            
            [self exportMVVideoWithPublishModel:willTransforToPublishModel
                                        succeed:^(AWEVideoPublishViewModel *result) {
                [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:NO];
                
                constructor(result);

                ACCBLOCK_INVOKE(transferHandler);
                
            } failed:^{
                [self p_monitorForSwithMode:NO totalCount:totalCount isToImageAlbum:NO];
                ACCBLOCK_INVOKE(deferBlock, NO, @"export MV Video faild");
            }];
        } else {
            ACCBLOCK_INVOKE(transferHandler);
        }

    } else {
        if (!willTransforToPublishModel.repoImageAlbumInfo.imageAlbumData) {
            // 首次从照片电影切换到图集
            [ACCMonitor() startTimingForKey:ACCMonitorImageAlbumTransferDurationMonitorKey];
            NSInteger totalCount = self.repository.repoUploadInfo.selectedUploadAssets.count;
            
            [self exportImageAlbumWithPublishModel:willTransforToPublishModel
                                           succeed:^(AWEVideoPublishViewModel *result) {
                [self p_monitorForSwithMode:YES totalCount:totalCount isToImageAlbum:YES];
                
                if (currentPublishModel.repoMusic.music) {
                    willTransforToPublishModel.repoMusic.music = currentPublishModel.repoMusic.music;
                    willTransforToPublishModel.repoMusic.musicSelectFrom = AWERecordMusicSelectSourceImageAlbumEditSwitched;
                }
                // 视频模式下切换到图片之前先更新视频，特别是贴纸
                [self updateDataVideoWithCompleteBlock:^{
                    ACCBLOCK_INVOKE(transferHandler);
                }];
            } failed:^{
                [self p_monitorForSwithMode:NO totalCount:totalCount isToImageAlbum:YES];
                ACCBLOCK_INVOKE(deferBlock, NO, @"export image album faild");
            }];
        } else {
            // 视频模式下切换到图片之前先更新视频，特别是贴纸
            [self updateDataVideoWithCompleteBlock:^{
                ACCBLOCK_INVOKE(transferHandler);
            }];
        }
    }
}

- (nullable id<ACCEditVideoDataProtocol>)fetchVideoDataWhenSmartMovieOpen:(AWEVideoPublishViewModel *)model
{
    if (!acc_isOpenSmartMovieCapabilities(model)) {
        return nil;
    }
    
    switch (self.smartMovieManager.previousScene) {
        case ACCSmartMovieSceneModeNone: {
            // 智照实验组1，默认去智照;智照实验组2，默认mv
            return [ACCSmartMovieABConfig defaultSmartMovie] ? model.repoSmartMovie.videoForSmartMovie : model.repoSmartMovie.videoForMV;
            break;
        }
        case ACCSmartMovieSceneModeMVVideo: {
            return model.repoSmartMovie.videoForMV;
            break;
        }
        case ACCSmartMovieSceneModeSmartMovie: {
            return model.repoSmartMovie.videoForSmartMovie;
            break;
        }
        default:
            break;
    }
    return nil;
}

- (BOOL)isGotoSmartMovieWithModel:(AWEVideoPublishViewModel *)model
{
    if (!acc_isOpenSmartMovieCapabilities(model)) {
        return NO;
    }
    
    if (self.smartMovieManager.previousScene == ACCSmartMovieSceneModeMVVideo) {
        return NO;
    }
    
    if (self.smartMovieManager.previousScene == ACCSmartMovieSceneModeSmartMovie) {
        return YES;
    }
    
    // previousScene没有被设置成过ACCSmartMovieSceneModeImageAlbum
    return [ACCSmartMovieABConfig defaultSmartMovie];
}

- (void)p_monitorForSwithMode:(BOOL)succeed totalCount:(NSInteger)totalCount isToImageAlbum:(BOOL)isToImageAlbum
{
    NSTimeInterval totalDuration = [ACCMonitor() timeIntervalForKey:ACCMonitorImageAlbumTransferDurationMonitorKey];
    
    NSDictionary * monitorExtra= @{@"pictureCount" : @(totalCount), @"duration" : @(totalDuration), @"type" : @(isToImageAlbum)};
    
    [ACCMonitor() trackService:ACCMonitorImageAlbumTransferErrorRateMonitorKey
                        status:succeed ? 0:1
                         extra:monitorExtra];
    
    if (succeed) {
        [ACCMonitor() trackService:ACCMonitorImageAlbumTransferDurationMonitorKey
                            status:0
                             extra:monitorExtra];
    }
}

- (void)updateDataVideoWithCompleteBlock:(void(^)(void))completeBlock
{
    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:self.repository.repoVideoInfo.video updateType:VEVideoDataUpdateAll completeBlock:^(NSError * _Nonnull error) {
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"ImageAlbumFlowComponent : update video error when switch video mode to image mode with error: %@", error);
        }
        ACCBLOCK_INVOKE(completeBlock);
    }];
}

- (void)exportImageAlbumWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                                 succeed:(void(^)(AWEVideoPublishViewModel *result))succeedBlock
                                  failed:(void(^)(void))failedBlock
{
    id<ACCImageAlbumAssetsExportManagerProtocol> exportManager = IESAutoInline(ACCBaseServiceProvider(), ACCImageAlbumAssetsExportManagerProtocol);
    [exportManager.class exportWithAssetModels:publishModel.repoUploadInfo.selectedUploadAssets
                                  publishModel:publishModel
                                    completion:^(BOOL succeed, id<ACCImageAlbumEditAssetsExportOutputDataProtocol> outputData) {
        if (!succeed || !outputData) {
            AWELogToolError(AWELogToolTagImport, @"TransferToImageManager : export faild");
            ACCBLOCK_INVOKE(failedBlock);
        } else {
            publishModel.repoContext.videoType = AWEVideoTypeImageAlbum;
            publishModel.repoUploadInfo.originUploadPhotoCount = @(publishModel.repoUploadInfo.selectedUploadAssets.count);
            [publishModel.repoVideoInfo updateVideoData:[ACCEditVideoDataFactory videoDataWithCacheDirPath:publishModel.repoDraft.draftFolder]];
            
            publishModel.repoImageAlbumInfo.transformContext = [[ACCRepoImageAlbumTransformContext alloc] initForImageAlbumEditContext];
            publishModel.repoImageAlbumInfo.imageEditOriginalImages = [outputData.originalImages copy];
            publishModel.repoImageAlbumInfo.imageEditBackupImages = [outputData.backupImages copy];
            publishModel.repoImageAlbumInfo.imageEditCompressedFramsImages = [outputData.compressedFramsImages copy];
            ACCBLOCK_INVOKE(succeedBlock, publishModel);
        }
    }];
}

- (void)exportMVVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                              succeed:(void(^)(AWEVideoPublishViewModel *result))succeedBlock
                               failed:(void(^)(void))failedBlock
{
    @weakify(self);
    [[AWEMVTemplateModel sharedManager] preFetchPhotoToVideoMusicList];
    self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
    self.mvTemplateManager.publishModel = [publishModel copy];

    self.mvTemplateManager.customerTransferHandler = ^(BOOL isCanceled, AWEVideoPublishViewModel *_Nullable result) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager = nil;
            self.mvTemplateManager.customerTransferHandler = nil;
            ACCBLOCK_INVOKE(succeedBlock, result);
        });
    };
    
    [self.mvTemplateManager exportMVVideoWithAssetModels:publishModel.repoUploadInfo.selectedUploadAssets failedBlock:^{
        @strongify(self);
        self.mvTemplateManager = nil;
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager = nil;
            self.mvTemplateManager.customerTransferHandler = nil;
            ACCBLOCK_INVOKE(failedBlock);
        });
    } successBlock:^{
        // 在customerTransferHandler中处理了
    }];
}

- (void)exportSmartMovieWithPublishModel:(AWEVideoPublishViewModel *_Nonnull)publishModel
                                 musicID:(NSString * _Nullable)musicID
                            succeedBlock:(void(^_Nullable)(BOOL isCanceled, AWEVideoPublishViewModel *result))succeedBlock
                             failedBlock:(void(^_Nullable)(void))failedBlock
{
    @weakify(self);
    self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
    self.mvTemplateManager.publishModel = [publishModel copy];

    self.mvTemplateManager.customerTransferHandler = ^(BOOL isCanceled, AWEVideoPublishViewModel *_Nullable result)
    {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager.customerTransferHandler = nil;
            self.mvTemplateManager = nil;
            ACCBLOCK_INVOKE(succeedBlock, isCanceled, result);
        });
    };
    
    [self.mvTemplateManager exportSmartMovieWithAssetModels:publishModel.repoUploadInfo.selectedUploadAssets
                                                    musicID:musicID
                                               needsLoading:NO
                                                failedBlock:^{
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager.customerTransferHandler = nil;
            self.mvTemplateManager = nil;
            ACCBLOCK_INVOKE(failedBlock);
        });
    } successBlock:^{
        // 在customerTransferHandler中处理了
    }];
}

#pragma mark - getter
- (ACCImageAlbumFlowViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCImageAlbumFlowViewModel.class];
        NSAssert(_viewModel, @"should not be nil");
    }
    return _viewModel;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return [self viewModel].inputData.publishModel;
}

- (id<ACCSmartMovieManagerProtocol>)smartMovieManager
{
    if (!_smartMovieManager) {
        _smartMovieManager = acc_sharedSmartMovieManager();
    }
    return _smartMovieManager;
}

- (BOOL)p_isLowLevelDeviceOpt
{
    if (ACCConfigBool(kConfigBool_enable_image_album_ve_editor_cache_opt)) {
        
        // ip7以下强制开启
        if (![UIDevice acc_isBetterThanIPhone7]) {
            return YES;
        }
        return  ACCConfigBool(kConfigBool_image_album_current_device_is_low_level_opt_target);
    }
    return NO;
}

#pragma mark - track
NS_INLINE void p_trackTransferWithTargetPublishModel(AWEVideoPublishViewModel *targetPublishModel)
{
    BOOL isImageTransferToVideo = !(targetPublishModel.repoImageAlbumInfo.isImageAlbumEdit);
    
    NSMutableDictionary *params = targetPublishModel.repoTrack.referExtra ? [targetPublishModel.repoTrack.referExtra mutableCopy] : [NSMutableDictionary dictionary];
    
    [params addEntriesFromDictionary:[targetPublishModel.repoTrack mediaCountInfo] ?: @{}];
    
    params[@"to_status"] =  isImageTransferToVideo? @"video":@"photo";
    
    [ACCTracker() trackEvent:@"click_transfer_icon"
                      params:params];
}

@end
