//
//  ACCRecordUploadButtonComponent.m
//  Pods
//
//  Created by songxiangwu on 2019/7/30.
//

#import "AWERepoStickerModel.h"
#import "AWERepoFlowControlModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCRecordUploadButtonComponent.h"
#import <CameraClient/ACCTransitioningDelegateProtocol.h>
#import <CameraClient/ACCAlbumInputData.h>
#import "AWEMVTemplateModel.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRecordTrackService.h>
#import <CreationKitComponents/ACCBeautyService.h>
#import <CreationKitComponents/ACCFilterService.h>
#import "ACCPropViewModel.h"
#import "ACCRecordUploadButtonViewModel.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCViewControllerProtocol.h"
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCRecordMode+UploadButton.h"
#import "CAKAlbumAssetModel+Convertor.h"
#import "ACCRepoRearResourceModel.h"
#import "ACCRepoMissionModelProtocol.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CameraClient/ACCFriendsServiceProtocol.h>
#import <CreativeAlbumKit/CAKAlbumViewController.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <CreativeAlbumKit/CAKAlbumAssetCache.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCRepoRecorderTrackerToolModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "ACCRepoLastGroupTrackModelProtocol.h"
#import <CameraClient/ACCKaraokeService.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import "ACCImageAlbumAssetsExportManagerProtocol.h"
#import <CameraClient/ACCDuetLayoutService.h>
#import <CameraClient/ACCUIReactTrackProtocol.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

static BOOL kCAKAlbumViewControllerNotAppear = YES;

@interface ACCRecordUploadButtonComponent () <ACCCameraLifeCircleEvent, PHPhotoLibraryChangeObserver, ACCRecorderViewContainerItemsHideShowObserver, ACCRecordSwitchModeServiceSubscriber, ACCKaraokeServiceSubscriber>


@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;

@property (nonatomic, assign) BOOL hasFetchedUploadImage; //第一次，回到前台（用户可能拍照了，跟ins一致）
@property (nonatomic, strong) ACCAnimatedButton *uploadVideoButton; // 上传视频按钮
@property (nonatomic, strong) UILabel *uploadVideoLabel; // 上传视频文字
@property (nonatomic, strong) UIImageView *photoImageView; // 上传视频按钮上的图片

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordTrackService> trackService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCBeautyService> beautyService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, strong) id<ACCFilterService> filterService;
@property (nonatomic, weak) id<ACCDuetLayoutService> duetService;

@property (nonatomic, assign) BOOL hasRegisterChangeObserver;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isImageAlbumEditGuideEntrance;
@property (nonatomic, assign) BOOL shouldShowMusicRecommendPropBubble;

@property (nonatomic, assign) BOOL vcPushed;
@property (nonatomic, strong) NSDictionary<CAKAlbumAssetCacheKey *, PHFetchResult *> *cachedAlbumData;

@end

@implementation ACCRecordUploadButtonComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, trackService, ACCRecordTrackService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, beautyService, ACCBeautyService)
IESAutoInject(self.serviceProvider, filterService, ACCFilterService)
IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)
IESAutoInject(self.serviceProvider, duetService, ACCDuetLayoutService)

#pragma mark - life cycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    if (self.hasRegisterChangeObserver) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

#pragma mark - ACCRecordUploadButtonComponentProtocol

- (void)updateUploadButtonHidden:(BOOL)hidden animated:(BOOL)animated
{
    hidden = hidden || [self needHiddenUploadButton];

    if (hidden) {
        [[AWERecorderTipsAndBubbleManager shareInstance] removeImageAlbumEditGuide];
    }
    
    if (!animated) {
        self.uploadVideoButton.hidden = hidden;
        self.photoImageView.hidden = hidden;
        self.uploadVideoLabel.hidden = hidden;
        return;
    }
    if (hidden) {
        [self.uploadVideoLabel acc_fadeHidden];
        [self.uploadVideoButton acc_fadeHidden];
        [self.photoImageView acc_fadeHidden];
    } else {
        if (![self viewModel].needHideUploadLabelBlock || ![self viewModel].needHideUploadLabelBlock()) {
            [self.uploadVideoLabel acc_fadeShow];
        }
        [self.uploadVideoButton acc_fadeShow];
        [self.photoImageView acc_fadeShow];
    }
}

- (BOOL)needHiddenUploadButton
{
    if (self.repository.repoDraft.isDraft) {
        return YES;
    }
    
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo && self.repository.repoDraft.isBackUp) {
        return YES;
    }
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return YES;
    }
    if (!self.switchModeService.currentRecordMode.isPhoto && !self.switchModeService.currentRecordMode.isVideo) {
        return YES;
    }
    if (self.repository.repoReshoot.isReshoot) {
        return YES;
    }
    if (self.viewContainer.isShowingAnyPanel || self.viewContainer.itemsShouldHide) {
        return YES;
    }
    if (self.repository.repoVideoInfo.fragmentInfo.count > 0) {
        return YES;
    }
    if ([self viewContainer].propPanelType != ACCRecordPropPanelNone) {
        return YES;
    }
    if (self.karaokeService.inKaraokeRecordPage) {
        return YES;
    }
    if (self.repository.repoDuet.isDuet && ![self.duetService supportImportAssetDuetLayout]) { // 合拍且是不支持导入的合拍布局
        return YES;
    }
    
    BOOL needHide = [self.hideUploadButtonPredicate evaluate];
    if (needHide) {
        return YES;
    }
    
    return NO;
}

- (void)refreshUploadImageView
{
    if ([UIDevice acc_isPoorThanIPhone6S]) {
        return;
    }
    
    PHAuthorizationStatus status = [ACCDeviceAuth acc_authorizationStatusForPhoto];
    if (status != PHAuthorizationStatusAuthorized) {
        return;
    }
#ifdef __IPHONE_14_0 //xcode12
    if (@available(iOS 14.0, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (status != PHAuthorizationStatusAuthorized && kCAKAlbumViewControllerNotAppear) {
            return;
        }
    }
#endif
    if (self.hasFetchedUploadImage) {
        return;
    }
    
    @weakify(self)
    [[[self p_getLatestImageAsset] takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(AWEAssetModel * assetModel) {
        @strongify(self)
        if (assetModel.asset) {
            [[[self p_getUIImageWithPHAsset:assetModel.asset] takeUntil:[self rac_willDeallocSignal]].deliverOnMainThread subscribeNext:^(RACTuple *  _Nullable x) {
                @strongify(self)
//                RACTupleUnpack(UIImage *photo, NSDictionary *info, NSNumber *isDegraded) = x;
                UIImage *photo = x.first;
                if (photo) {
                    self.hasFetchedUploadImage = YES;
                    self.photoImageView.image = photo;
                }
            }];
        }
    }];
}

- (RACSignal *)p_getLatestImageAsset
{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id < RACSubscriber >
    _Nonnull subscriber) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [CAKPhotoManager getLatestAssetCount:1
                                       sortStyle:ACCConfigInt(kConfigInt_album_asset_sort_style)
                                            type:AWEGetResourceTypeImage
                                      completion:^(NSArray<CAKAlbumAssetModel *> *latestAssets) {
                if (!ACC_isEmptyArray(latestAssets)) {
                    [subscriber sendNext:[latestAssets.firstObject convertToStudioAsset]];
                    [subscriber sendCompleted];
                }
            }];
        });
        return nil;
    }];
}

- (RACSignal *)p_getUIImageWithPHAsset:(PHAsset *)asset
{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id < RACSubscriber >
    _Nonnull subscriber) {
        CGFloat scale = [UIScreen mainScreen].scale;
        [CAKPhotoManager getUIImageWithPHAsset:asset imageSize:CGSizeMake(36 * scale, 36 * scale) networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
            AWELogToolError(AWELogToolTagImport, @"error: %@",error);
        } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            [subscriber sendNext:RACTuplePack(photo,info, @(isDegraded))];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (BOOL)p_hasProp
{
    ACCRepoRearResourceModel *rearResource = [self.repository extensionModelOfClass:ACCRepoRearResourceModel.class];
    if (rearResource.stickerIDArray.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - action
- (void)showUploadVideoViewControllerWithSender:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    
    [self showUploadVideoViewController];
}

- (void)showUploadVideoViewController
{
    [ACCMonitor() startTimingForKey:@"click_upload_button"];
    [self trackPreviewPerformanceWithNextAction:@"click_upload_button"];
    if (self.cameraService.recorder.isRecording) {
        return;
    }
    
    if (![[AWERecorderTipsAndBubbleManager shareInstance] isImageAlbumGuideShowing]) {
        self.isImageAlbumEditGuideEntrance = NO;
    }
    
    [[AWEMVTemplateModel sharedManager] preFetchPhotoToVideoMusicList];
    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    [[AWERecorderTipsAndBubbleManager shareInstance] removeImageAlbumEditGuide];
    
    [ACCTracker() trackEvent:@"upload_click"
                                      label:@"shoot_page"
                                      value:nil
                                      extra:nil
                                 attributes:@{@"enter_from" : self.repository.repoFlowControl.enterFromType == AWERecordEnterFromTypeMusicDetail ? @"single_song" : @"direct_shoot"}];
    NSMutableDictionary *referExtra = [self.repository.repoTrack.referExtra mutableCopy];
    NSString *eventName = @"click_upload_entrance";
    if (self.repository.repoContext.recordSourceFrom != AWERecordSourceFromUnknown) {
        eventName = @"im_click_upload_entrance";
        referExtra[@"shoot_way"] = self.viewModel.inputData.publishModel.repoTrack.referString ?: @"";
        referExtra[@"entrance"] = self.viewModel.inputData.publishModel.repoTrack.entrance ?: @"";
    }
    referExtra[@"is_meteormode"] = @(self.repository.repoContext.isMeteorMode ? 1 : 0);
   
    [referExtra removeObjectForKey:@"enter_method"];
    referExtra[@"enter_from"] = @"video_shoot_page";
    [referExtra addEntriesFromDictionary:[self.repository.repoSticker videoCommentStickerTrackInfo]];
    if ([eventName isEqualToString:@"click_upload_entrance"]) {
        id<ACCRepoLastGroupTrackModelProtocol> groupTrackModel = [self.viewModel.inputData.publishModel extensionModelOfProtocol:@protocol(ACCRepoLastGroupTrackModelProtocol)];
        referExtra[@"from_group_id"] = groupTrackModel.fromGroupID;
        referExtra[@"last_group_id"] = groupTrackModel.lastGroupID;
    }
    referExtra[@"enter_method"] = @"shoot_icon";
    [ACCTracker() trackEvent:eventName params:referExtra needStagingFlag:NO];

    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        [self p_presentUploadVideoViewController];
    } else {
        @weakify(self);
        [ACCDeviceAuth requestPhotoLibraryPermission:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self p_presentUploadVideoViewController];
                [self addPHPhotoLibraryObserver];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedString(@"tip",@"tip") message:ACCLocalizedString(@"com_mig_failed_to_access_photos_please_go_to_the_settings_to_enable_access", @"相册权限被禁用，请到设置中授予抖音允许访问相册权限")  preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"go_to_settings",@"go_to_settings") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"cancel",@"cancel") style:UIAlertActionStyleCancel handler:nil]];
                [ACCAlert() showAlertController:alertController animated:YES];
            }
        }];
    }
}

#pragma mark 拍摄页打开相册
- (void)p_presentUploadVideoViewController
{
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickAlbum];
    BOOL isFromIMStory = self.repository.repoContext.isIMRecord;
    ACCAlbumVCType type = (self.repository.repoFlowControl.enterFromType == AWERecordEnterFromTypeMusicDetail ? ACCAlbumVCTypeForMusicDetail : ACCAlbumVCTypeForUpload);
    if (isFromIMStory) {
        type = ACCAlbumVCTypeForStory;
    }
    
    if (self.repository.repoDuet.isDuet) { // 合拍且是支持导入素材的合拍布局
        if ([self.duetService supportImportAssetDuetLayout]) {
            type = ACCAlbumVCTypeForDuet;
        } else {
            AWELogToolError2(@"duet", AWELogToolTagRecord, @"unsupport import asset duet layout.");
            return;
        }
    }
    
    ACCAlbumInputData *inputData = [[ACCAlbumInputData alloc] init];
    inputData.originUploadPublishModel = self.viewModel.inputData.publishModel;
    inputData.originUploadPublishModel.repoUploadInfo.extraDict[@"enter_method_album"] = @"click_album";
    inputData.originUploadPublishModel.repoTrack.enterMethod = @"shoot_icon";
    inputData.vcType = type;
    inputData.isFromShootingPageOrPlusButton = YES;
    if (self.isImageAlbumEditGuideEntrance) {
        inputData.defaultTabIdentifier = CAKAlbumTabIdentifierImage;
    }
    @weakify(self);
    inputData.dismissBlock = ^{
        @strongify(self);
        [ACCDraft() setCacheDirPathWithID:self.repository.repoDraft.taskID];
    };
    CAKAlbumViewController *selectAlbumViewController = [IESAutoInline(ACCBaseServiceProvider(), ACCSelectAlbumAssetsProtocol) albumViewControllerWithInputData:inputData];
    selectAlbumViewController.prefetchData = self.cachedAlbumData;

    if (self.repository.repoMusic.music.loaclAssetUrl) {
        // 升级音乐文件查找地址
        self.repository.repoMusic.music.loaclAssetUrl = [ACCVideoMusic() localURLForMusic:self.repository.repoMusic.music];
    }
    [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
    // PM要求重进打开相册清除之前的图集自选音乐，重新使用热歌
    [ACCImageAlbumAssetsExportManager() clearLastSelectedMusicCache];
    
    UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:selectAlbumViewController];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transitionDelegate;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    [self.transitionDelegate.swipeInteractionController wireToViewController:navigationController.topViewController];
    self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = YES;
    [ACCToolUIReactTrackService() eventEnd:kAWEUIEventLatestEvent withPublishModel:self.viewModel.inputData.publishModel];
    [self.controller.root presentViewController:navigationController animated:YES completion:^{
        @strongify(self);
        self.vcPushed = YES;
        kCAKAlbumViewControllerNotAppear = NO;
        [self refreshUploadImageView];
        [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
        [self.viewModel.uploadVCShowedSubject sendNext:@YES];
    }];
}

- (void)p_prefetchAlbumAssetData {
    ACCAlbumLandingOptimizeType type = ACCConfigEnum(kConfigInt_album_landing_optimize_type, ACCAlbumLandingOptimizeType);
    if (type & ACCAlbumLandingOptimizeTypeCache && !ACCConfigBool(kConfigBool_enable_album_data_multithread_opt)) {
        // prefetch album list
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        #ifdef __IPHONE_14_0 //xcode12
            if (@available(iOS 14.0, *)) {
                status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
            }
        #endif
            if (status != PHAuthorizationStatusAuthorized) {
                return;
            }
            [CAKPhotoManager getAllAssetsWithType:AWEGetResourceTypeImageAndVideo sortStyle:ACCConfigInt(kConfigInt_album_asset_sort_style) ascending:YES completion:^(PHFetchResult *result) {
                acc_dispatch_main_async_safe(^{
                    CAKAlbumAssetCacheKey *cacheKey = [CAKAlbumAssetCacheKey keyWithAscending:YES type:AWEGetResourceTypeImageAndVideo localizedTitle:nil];
                    self.cachedAlbumData = result ? @{cacheKey: result} : @{};
                });
            }];
        });
    }
}

#pragma mark - ACCCompoonentProtocol

- (void)componentDidAppear
{
    if (!self.repository.repoDuet.isDuet) {
        // 如果还没申请权限先不弹
        if (self.repository.repoRecorderTrackerTool.hasAuthority) {
            
            BOOL didShowImageAlbumEditGuide = [[AWERecorderTipsAndBubbleManager shareInstance] showImageAlbumEditGuideIfNeededForView:self.uploadVideoButton containerView:self.viewContainer.rootView];
            
            // 不能粗暴的 isImageAlbumEditGuideEntrance = didShowImageAlbumEditGuide
            // 因为展示过一次以后这里不会再展示，但是isImageAlbumEditGuideEntrance仍然是true
            if (didShowImageAlbumEditGuide) {
                self.isImageAlbumEditGuideEntrance = YES;
                
                [ACCTracker() trackEvent:@"camera_photo_guidance_show"
                                  params:@{
                                      @"shoot_way" : self.repository.repoTrack.referString ?: @"",
                                      @"creation_id" : self.repository.repoContext.createId ?: @"",
                                      @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
                                  }];
            }
        }
    }
    
    [[[self viewModel] viewDidAppearSubject] sendNext:@(YES)];
    if (!self.isImageAlbumEditGuideEntrance && !self.shouldShowMusicRecommendPropBubble && [self.repository.repoTrack.referString isEqualToString:@"direct_shoot"] && self.isFirstAppear && ![self p_hasProp]) {
    }
    
    if (!self.isFirstAppear && self.vcPushed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCRecordUploadButtonComponentDidShow object:nil];
    }
}

- (void)loadComponentView
{
    if ([self showUploadButton]) {
        [self setupUI];
        @weakify(self);
        [[[[[self viewModel] cameraStartRenderSubject] zipWith:[[self viewModel] viewDidAppearSubject]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            [self refreshUploadImageView];
        }];
        
        if (self.repository.repoDuet.isDuet && [self.duetService enableDuetImportAsset]) {
            [[self.duetService.applyDuetLayoutSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
                @strongify(self);
                [self updateUploadButtonHidden:NO animated:YES];
            }];
        }
    }
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    
    ACCAlbumLandingOptimizeType type = ACCConfigEnum(kConfigInt_album_landing_optimize_type, ACCAlbumLandingOptimizeType);
    [CAKPhotoManager setEnableAlbumLoadOpt:type & ACCAlbumLandingOptimizeTypeCache];
    
    if ([self showUploadButton]) {
        if (![self.controller enableFirstRenderOptimize]) {
            [self loadComponentView];
        }
        [self.viewContainer addObserver:self];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

        @weakify(self);
        [[RACObserve(self.viewContainer, propPanelType) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            if ([self viewContainer].itemsShouldHide) {
                [self updateUploadButtonHidden:YES animated:NO];
            } else {
                [self updateUploadButtonHidden:x.integerValue != ACCRecordPropPanelNone animated:NO];
            }
        }];
        
        [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            ACCCameraRecorderState state = x.integerValue;
            switch (state) {
                case ACCCameraRecorderStateNormal: {
                    [self updateUploadButtonHidden:self.repository.repoGame.gameType != ACCGameTypeNone animated:YES];
                    break;
                }
                case ACCCameraRecorderStatePausing: {
                    if (!ACC_isEmptyString(self.viewModel.inputData.publishModel.repoProp.liveDuetPostureImagesFolderPath)) {
                        [self updateUploadButtonHidden:YES animated:YES];
                    } else {
                        if (self.repository.repoGame.gameType == ACCGameTypeNone) {
                            [self updateUploadButtonHidden:NO animated:YES];
                        }
                    }
                    break;
                }
                case ACCCameraRecorderStateRecording: {
                    [self updateUploadButtonHidden:YES animated:YES];
                    break;
                }
                default:
                    break;
            }
        }];
        [self.switchModeService addSubscriber:self];
        [self.karaokeService addSubscriber:self];
    }

    self.shouldShowMusicRecommendPropBubble = [[AWERecorderTipsAndBubbleManager shareInstance] shouldShowMusicRecommendPropBubbleWithInputData:self.viewModel.inputData isShowingPanel:self.viewContainer.isShowingPanel];
    
    id<ACCRepoMissionModelProtocol> missionModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoMissionModelProtocol)];
    if ([missionModel acc_isRecordLiveMission] || self.repository.repoChallenge.challenge.task.isLiveRecord) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACCRecordUploadButtonComponentDidMount object:nil];
        [self showUploadVideoViewController];
    }
}

- (void)componentDidUnmount
{
    if (self.showUploadButton) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    acc_dispatch_main_async_safe(^{
        self.hasFetchedUploadImage = NO;
        [self refreshUploadImageView];
    });
}

- (void)setupUI
{
    [self.viewContainer.layoutManager addSubview:self.uploadVideoButton viewType:ACCViewTypeUploadVideoButton];
    [self.viewContainer.layoutManager addSubview:self.uploadVideoLabel viewType:ACCViewTypeUploadVideoLabel];
    [self.uploadVideoButton addTarget:self action:@selector(showUploadVideoViewController) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - ACCCameraLifeCircleEvent

- (void)onCameraDidStartRender:(id<ACCCameraService>)cameraService {
    [[[self viewModel] cameraStartRenderSubject] sendNext:@(YES)];
    [self p_prefetchAlbumAssetData];
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{

    if (!ACC_isEmptyString(self.repository.repoProp.liveDuetPostureImagesFolderPath)) {
        [self updateUploadButtonHidden:YES animated:YES];
    } else {
        [self updateUploadButtonHidden:!show animated:animated];
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (mode.modeId == ACCRecordModeKaraoke) {
        [self updateUploadButtonHidden:YES animated:YES];
    } else {
        [self updateUploadButtonHidden:NO animated:YES];
    }
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self updateUploadButtonHidden:state animated:YES];
}

#pragma mark - track

- (void)trackPreviewPerformanceWithNextAction:(NSString *)nextAction
{
    NSString *resolution = [NSString stringWithFormat:@"%@*%@",@([self.cameraService.cameraControl outputSize].width),@([self.cameraService.cameraControl outputSize].height)];
    NSInteger beautyStatus = [self.beautyService isUsingBeauty] ? 1:0;
    
    NSDictionary *info = @{
        @"beauty_status":@(beautyStatus),
        @"resolution":resolution,
        @"effect_id":self.propViewModel.currentSticker.effectIdentifier ?:@"",
        @"filter_id":[self filterService].currentFilter.effectIdentifier ?: ([self filterService].hasDeselectionBeenMadeRecently ? @"-1" : @""),
        @"appstate" : @(self.viewModel.inputData.firstCaptureAppState)
    };
    [self.trackService trackPreviewPerformanceWithInfo:info nextAction:nextAction];
}

#pragma mark - getter & setter

- (BOOL)showUploadButton
{
    if (!ACC_isEmptyString(self.repository.repoProp.liveDuetPostureImagesFolderPath)) {
        return NO;
    }
    
    BOOL showUploadButton = self.repository.repoDuet.isDuet ? [self.duetService enableDuetImportAsset] : YES;
    BOOL isPhotoToVideoDraftOrBackup = (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) && AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType;
    showUploadButton = showUploadButton && !isPhotoToVideoDraftOrBackup;
    return showUploadButton;
}

- (ACCAnimatedButton *)uploadVideoButton
{
    if (!_uploadVideoButton) {
        _uploadVideoButton = [[ACCAnimatedButton alloc] init];
        [_uploadVideoButton addSubview:self.photoImageView];
        ACCMasMaker(self.photoImageView, {
            make.edges.equalTo(_uploadVideoButton);
        });
        _uploadVideoButton.layer.shadowOffset = CGSizeMake(0, 1);
        _uploadVideoButton.layer.shadowColor = ACCResourceColor(ACCUIColorConstSDInverse).CGColor;
        _uploadVideoButton.layer.shadowRadius = 1;
        _uploadVideoButton.accessibilityLabel = ACCLocalizedString(@"upload_entrance_name", nil);
    }
    return _uploadVideoButton;
}

- (UILabel *)uploadVideoLabel
{
    if (!_uploadVideoLabel) {
        _uploadVideoLabel = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:11]
                                textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                     text:ACCLocalizedString(@"upload_entrance_name", nil)];
        _uploadVideoLabel.textAlignment = NSTextAlignmentCenter;
        _uploadVideoLabel.numberOfLines = 2;
        _uploadVideoLabel.preferredMaxLayoutWidth = 90;
        _uploadVideoLabel.isAccessibilityElement = NO;
    }
    return _uploadVideoLabel;
}

- (UIImageView *)photoImageView
{
    if (!_photoImageView) {
        
        _photoImageView = [[UIImageView alloc] init];
        _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
        _photoImageView.image = ACCResourceImage(@"bgAlbumCover");
        _photoImageView.layer.borderWidth = 2;
        _photoImageView.layer.borderColor = ACCResourceColor(ACCUIColorConstTextInverse).CGColor;
        _photoImageView.layer.cornerRadius = 4;
        _photoImageView.layer.masksToBounds = YES;
        _photoImageView.layer.allowsEdgeAntialiasing = YES;
    }
    return _photoImageView;
}

-(id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transitionDelegate;
}

- (ACCRecordUploadButtonViewModel *)viewModel
{
    ACCRecordUploadButtonViewModel *viewModel = [self getViewModel:ACCRecordUploadButtonViewModel.class];
    return viewModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.cameraService addSubscriber:self];
}

- (ACCGroupedPredicate *)hideUploadButtonPredicate
{
    if (!_hideUploadButtonPredicate) {
        _hideUploadButtonPredicate = [[ACCGroupedPredicate alloc] initWithOperand:ACCGroupedPredicateOperandOr];
    }
    return _hideUploadButtonPredicate;
}

#pragma mark - utils

- (void)addPHPhotoLibraryObserver
{
    // 未授权状态不添加监听
    if ([ACCDeviceAuth isiOS14PhotoNotDetermined]) {
        return;
    }
    if (@available(iOS 14.0, *)) {
        if (!self.hasRegisterChangeObserver) {
            self.hasRegisterChangeObserver = YES;
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
    }
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hasFetchedUploadImage = NO;
        self.photoImageView.image = ACCResourceImage(@"bgAlbumCover");
        [self refreshUploadImageView];
        [self p_prefetchAlbumAssetData];
    });
}

@end
