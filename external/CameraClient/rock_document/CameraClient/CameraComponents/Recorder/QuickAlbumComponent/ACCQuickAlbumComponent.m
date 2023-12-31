//
//  ACCQuickAlbumComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/8 17:49.
//	Copyright © 2020 Bytedance. All rights reserved.

#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"
#import "ACCAPPSettingsProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeAlbumKit/CAKPhotoManager.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import "ACCMVTemplateManagerProtocol.h"
#import "ACCQuickAlbumComponent.h"
#import "ACCQuickAlbumContainerView.h"
#import "ACCQuickAlbumViewModel.h"
#import "ACCQuickStoryRecorderTipsViewModel.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCSpeedControlViewModel.h"
#import "ACCFocusViewModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "AWECameraFeatureButtonPassThroughView.h"
#import "AWEMVTemplateModel.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import "ACCQuickAlbumExportProtocol.h"
#import "ACCRecordFlowService.h"
#import "ACCPropViewModel.h"
#import "ACCRecordCloseViewModel.h"
#import "ACCRecordUploadButtonViewModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "ACCRecordGestureService.h"
#import "CAKAlbumAssetModel+Convertor.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "ACCFlowerService.h"
#import "ACCExifUtil.h"

@interface ACCQuickAlbumComponent () <
ACCRecordSwitchModeServiceSubscriber,
ACCQuickAlbumContainerViewDelegate,
AWECameraFeatureButtonPassThroughViewDelegate,
PHPhotoLibraryChangeObserver,
ACCRecorderViewContainerItemsHideShowObserver,
ACCRecordGestureServiceSubscriber>

@property (nonatomic, weak) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordGestureService> gestureService;
@property (nonatomic, strong) id<ACCFlowerService> flowerService;
@property (nonatomic, strong) id<ACCMVTemplateManagerProtocol> mvTemplateManager;
@property (nonatomic, strong) id<ACCQuickAlbumExportProtocol> videoExport;
@property (nonatomic, strong) UIView<ACCTextLoadingViewProtcol>* loadingView;

@property (nonatomic, strong) ACCQuickAlbumContainerView *quickAlbumView;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL hasRegisterChangeObserver;
@property (nonatomic, assign) BOOL hasBindViewModel;
@property (nonatomic, assign) BOOL hasSticker;
@property (nonatomic, assign) BOOL shouldShowMusicRecommendPropBubble;
@property (nonatomic, assign) BOOL hasLoadPreData;
@property (nonatomic, strong) AWECameraFeatureButtonPassThroughView *passThroughView;
@property (nonatomic, strong) NSString *enterMethod;
@property (nonatomic, assign) PHImageRequestID currentId;

@end

@implementation ACCQuickAlbumComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, gestureService, ACCRecordGestureService)
IESAutoInject(self.serviceProvider, flowerService, ACCFlowerService)


- (void)dealloc
{
    if (self.hasRegisterChangeObserver) {
         [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

- (void)loadComponentView
{
    id<ACCRecorderBarItemContainerView> toolBarContainerView = self.viewContainer.barItemContainer;
    [toolBarContainerView addMaskViewAboveToolBar:self.passThroughView];
}

#pragma mark - life cycle
- (void)componentDidMount
{
    [self p_bindViewModelIfNeed];

    @weakify(self);
    [[self viewModel].quickAlbumShowOrHideSignal.deliverOnMainThread subscribeNext:^(RACTuple *x) {
        @strongify(self);
        RACTupleUnpack(NSNumber * isShow, NSNumber * isBlank) = x;
        [self.quickAlbumView quickAlbumHasShow];
        if ([isShow boolValue]) {
            if ([self canShowQuickAlbum]) {
                [self showQuickAlbum:@{@"enter_method": @"slide_up", @"event": @"fast_upload_photo_show"}];
            }
        } else {
            if ([isBlank boolValue]) {
                [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"}];
            } else {
                [self hideQuickAlbum:@{@"enter_method": @"slide_down", @"event": @"fast_upload_photo_close"}];
            }
        }
    }];

    self.hasSticker = [self propViewModel].appliedLocalEffect != nil;
    self.shouldShowMusicRecommendPropBubble = [[AWERecorderTipsAndBubbleManager shareInstance] shouldShowMusicRecommendPropBubbleWithInputData:[self viewModel].inputData isShowingPanel:self.viewContainer.isShowingPanel];

    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }

    self.isFirstAppear = YES;
}

- (void)p_bindViewModelIfNeed
{
    if (self.hasBindViewModel) {
        return;
    }
    self.hasBindViewModel = YES;

    @weakify(self);
    id<ACCRecorderViewContainer> viewContainer = IESAutoInline(self.serviceProvider, ACCRecorderViewContainer);
    [[RACObserve(viewContainer, propPanelType) deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.integerValue != 0) {
            [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"}];
        }
    }];
    [viewContainer addObserver:self];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber *_Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateRecording:
                [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"} hiddenAnimated:NO];
                break;
            default:
                break;
        }
    }];

    //close
    [[self closeViewModel].manullyClickCloseButtonSuccessfullyCloseSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if ([self hasAuthorized]) {
            [[PHImageManager defaultManager] cancelImageRequest:self.currentId];
        }
        [self.quickAlbumView unobserveKVO];
    }];

    //prop
    [[self propViewModel].didSetCurrentStickerSignal.deliverOnMainThread subscribeNext:^(ACCRecordSelectEffectPack _Nullable x) {
        @strongify(self);
        RACTupleUnpack(IESEffectModel * sticker, __unused IESEffectModel * oldSticker) = x;
        self.hasSticker = sticker != nil;
        if (self.hasSticker) {
            [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"}];
        }
    }];
    
    [[self propViewModel].didApplyLocalStickerSignal.deliverOnMainThread subscribeNext:^(IESEffectModel *sticker) {
        @strongify(self);
        if (sticker) {
            self.hasSticker = YES;
            [[self viewModel] showOrHideQuickAlbum:NO];
        }
    }];
    
    [[self uploadButtonViewModel].uploadVCShowedSubject.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [[self viewModel] showOrHideQuickAlbum:NO];
    }];

    [self addPHPhotoLibraryObserver];
}

- (void)componentWillAppear
{
    if (self.isFirstAppear) {
        [self showOrHideQuickAlbumIfNeeded:@{@"enter_method": @"auto", @"event": @"fast_upload_photo_show"}];
        self.isFirstAppear = NO;
    }
}

#pragma mark - Quick Album

- (void)showOrHideQuickAlbumIfNeeded:(NSDictionary *)trackInfo
{
    if ([self canShowQuickAlbum] && [self canFirstShowQuickAlbum]) {
        [self showQuickAlbum:trackInfo];
    } else {
        [self hideQuickAlbum:trackInfo];
    }
}

- (void)showQuickAlbum:(NSDictionary *)trackInfo
{
    if (trackInfo[@"enter_method"]) {
        self.enterMethod = trackInfo[@"enter_method"];
    }

    [self p_bindViewModelIfNeed];

    if (self.viewModel.isQuickAlbumShow) {
        return;
    }

    [self trackEvent:trackInfo];

    if (!self.hasLoadPreData) {
        @weakify(self);
        [self fetchPreVisibleAssetsWithCompletion:^(NSArray<AWEAssetModel *> *assets) {
            @strongify(self);
            if (assets.count >= 5) {
                self.hasLoadPreData = YES;
                acc_dispatch_main_async_safe(^{
                    [self.viewContainer.layoutManager addSubview:self.quickAlbumView viewType:ACCViewTypeQuickAlbum];
                    [self.quickAlbumView setQuickAlbumDatasource:assets];

                    self.quickAlbumView.alpha = 0.f;
                    self.quickAlbumView.acc_bottom = self.quickAlbumView.acc_bottom + 50;

                    if ([self.switchModeService isInSegmentMode]) {
                        [[self tipsViewModel] shouldShowSwitchLengthView:NO];
                    }
                    self.viewModel.isQuickAlbumShow = YES;

                    [UIView animateWithDuration:0.25f
                                     animations:^{
                                         self.quickAlbumView.alpha = 1.f;
                                         self.quickAlbumView.acc_bottom = self.quickAlbumView.acc_bottom - 50;
                                     }];
                });
            } else {
                self.viewModel.isQuickAlbumShow = NO;
            }
        }];
    } else {
        if ([self.switchModeService isInSegmentMode]) {
            [[self tipsViewModel] shouldShowSwitchLengthView:NO];
        }
        self.viewModel.isQuickAlbumShow = YES;
        [UIView animateWithDuration:0.25f
                         animations:^{
                             self.quickAlbumView.alpha = 1.f;
                             self.quickAlbumView.acc_bottom = self.quickAlbumView.acc_bottom - 50;
                         }];
    }
}

- (void)hideQuickAlbum:(NSDictionary *)trackInfo
{
    [self hideQuickAlbum:trackInfo isFromPassThrough:NO];
}

- (void)hideQuickAlbum:(NSDictionary *)trackInfo isFromPassThrough:(BOOL)isFromPassThrough
{
    [self hideQuickAlbum:trackInfo isFromPassThrough:isFromPassThrough hiddenAnimated:YES];
}

- (void)hideQuickAlbum:(NSDictionary *)trackInfo hiddenAnimated:(BOOL)animated
{
    [self hideQuickAlbum:trackInfo isFromPassThrough:NO hiddenAnimated:animated];
}

- (void)hideQuickAlbum:(NSDictionary *)trackInfo isFromPassThrough:(BOOL)isFromPassThrough hiddenAnimated:(BOOL)animated
{
    if (!self.viewModel.isQuickAlbumShow) {
        return;
    }

    self.viewModel.isQuickAlbumShow = NO;
    [self trackEvent:trackInfo];

    if (self.quickAlbumView) {
        if ([self.switchModeService isInSegmentMode]) {
            [[self tipsViewModel] shouldShowSwitchLengthView:YES];
        }

        [UIView animateWithDuration: animated ? 0.25 : 0
                         animations:^{
                             self.quickAlbumView.alpha = 0.f;
                             self.quickAlbumView.acc_bottom = self.quickAlbumView.acc_bottom + 50;
                         }];

    }
}

- (BOOL)canShowQuickAlbum
{
    if (self.flowService.videoSegmentsCount > 0) {
        return NO;
    }

    if ([self publishModel].repoDuet.isDuet) {
        return NO;
    }

    if ([self publishModel].repoDraft.isDraft) {
        return NO;
    }

    if (self.hasSticker) {
        return NO;
    }

    if (self.shouldShowMusicRecommendPropBubble) {
        return NO;
    }

    if (![self currentRecordModeCanShow]) {
        return NO;
    }

    if (![self hasAuthorized]) {
        return NO;
    }

    // 快拍反转
    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return NO;
    }
    
    if(self.flowerService.inFlowerPropMode){
        return NO;
    }

    return YES;
}

- (BOOL)canFirstShowQuickAlbum
{
    if (![self hasAuthorized]) {
        return NO;
    }

    BOOL onlyShowForActiveness = ACCConfigBool(kConfigBool_quick_upload_only_low_activeness) ? [ACCAPPSettings() isLowPublishActiveness] : YES;
    if (!onlyShowForActiveness) {
        return NO;
    }

    if (![self currentReferCanShow]) {
        return NO;
    }

    if (![self currentRecordModeCanFold]) {
        return NO;
    }

    if ([self viewContainer].propPanelType != ACCRecordPropPanelNone) {
        return NO;
    }

    return YES;
}

- (BOOL)currentRecordModeCanShow
{
    NSInteger mode = self.switchModeService.currentRecordMode.modeId;
    return ACCRecordModeStory == mode
    || [self.switchModeService isInSegmentMode]
    || ACCRecordModeTakePicture == mode;
}

- (BOOL)currentRecordModeCanFold
{
    NSInteger mode = self.switchModeService.currentRecordMode.modeId;
    return ACCRecordModeStory == mode;
}

#pragma mark - Track
- (void)trackEvent:(NSDictionary *)extraInfo
{
    NSMutableDictionary *paras = [NSMutableDictionary dictionaryWithDictionary:extraInfo];
    NSString *eventName;
    if (extraInfo[@"event"]) {
        eventName = [NSString stringWithFormat:@"%@", extraInfo[@"event"]];
        [paras removeObjectForKey:@"event"];

        [paras addEntriesFromDictionary:[self publishModel].repoTrack.commonTrackInfoDic];

        [ACCTracker() trackEvent:eventName params:paras];
    }
}

#pragma mark - Get/Set
- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.gestureService addSubscriber:self];
}

- (ACCQuickAlbumViewModel *)viewModel
{
    return [self getViewModel:[ACCQuickAlbumViewModel class]];
}

- (ACCQuickStoryRecorderTipsViewModel *)tipsViewModel
{
    return [self getViewModel:[ACCQuickStoryRecorderTipsViewModel class]];
}

- (AWECameraFeatureButtonPassThroughView *)passThroughView
{
    if (!_passThroughView) {
        _passThroughView = [[AWECameraFeatureButtonPassThroughView alloc] init];
        _passThroughView.delegate = self;
    }
    return _passThroughView;
}

- (ACCSpeedControlViewModel *)speedControlViewModel
{
    return [self getViewModel:[ACCSpeedControlViewModel class]];
}

- (AWEVideoPublishViewModel *)publishModel
{
    return [self viewModel].inputData.publishModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (ACCQuickAlbumContainerView *)quickAlbumView
{
    if(!_quickAlbumView) {
        _quickAlbumView = [[ACCQuickAlbumContainerView alloc] init];
        _quickAlbumView.delegate = self;
    }
    return _quickAlbumView;
}

- (void)setLoadingView:(UIView<ACCTextLoadingViewProtcol> *)loadingView
{
    if (_loadingView) {
        [_loadingView dismissWithAnimated:NO];
        _loadingView = nil;
    }
    _loadingView = loadingView;
}

- (ACCRecordCloseViewModel *)closeViewModel
{
    ACCRecordCloseViewModel *closeViewModel = [self getViewModel:ACCRecordCloseViewModel.class];
    return closeViewModel;
}

- (ACCRecordUploadButtonViewModel *)uploadButtonViewModel
{
    return [self getViewModel:[ACCRecordUploadButtonViewModel class]];
}

- (ACCFocusViewModel *)focusViewModel
{
    ACCFocusViewModel *focusViewModel = [self getViewModel:ACCFocusViewModel.class];
    NSAssert(focusViewModel, @"should not be nil");
    return focusViewModel;
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    if (!show) {
        [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"}];
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"}];
}

#pragma mark - ACCQuickAlbumContainerViewDelegate
- (void)quickAlbumCollectionViewDidSelected:(AWEAssetModel *)model completion:(void (^)(void))completion
{
    [self trackEvent:@{
        @"event": @"fast_upload_photo_click",
        @"enter_method": (self.enterMethod ?: @""),
        @"type": model.mediaType == AWEAssetModelMediaTypePhoto ? @"photo" : @"video"
    }];
    
    NSMutableArray *locationInfos = [NSMutableArray array];
    if (ACCConfigBool(kConfigBool_enable_upload_more_location_informations)) {
        [locationInfos acc_addObject:model.asset.acc_location];
    }

    @weakify(self);
    if (model.mediaType == AWEAssetModelMediaTypePhoto) {
        self.loadingView = [[IESAutoInline(ACCBaseServiceProvider(), ACCLoadingProtocol) class] showWindowLoadingWithTitle:@"" animated:YES];
        ACCBLOCK_INVOKE(completion);
        [[AWEMVTemplateModel sharedManager] preFetchPhotoToVideoMusicList];
        self.mvTemplateManager = nil;
        self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
        self.mvTemplateManager.publishModel = [self publishModel].copy;
        self.mvTemplateManager.publishModel.repoUploadInfo.extraDict[@"enter_method_album"] = @"click_fast_album";
        [self.mvTemplateManager exportMVVideoWithAssetModels:@[model]
                                                 failedBlock:^{
            [ACCToast() showError:ACCLocalizedString(@"com_mig_there_was_a_problem_with_the_internet_"
                                                     @"connection_try_again_later_yq455g",
                                                     @"There was a problem with the internet "
                                                     @"connection. Try again later.")];
            [self.loadingView dismissWithAnimated:YES];
        }
                                                successBlock:^{
            @strongify(self);
            self.mvTemplateManager = nil;
            [self.loadingView dismissWithAnimated:YES];
        }];
    } else if (model.mediaType == AWEAssetModelMediaTypeVideo) {
        [self fetchVideoAsset:model progress:^(double process, NSError *error) {
            if (error != nil) {
                AWELogToolError(AWELogToolTagRecord, @"request assets from icloud error: %@", error);
                model.didFailFetchingiCloudAsset = YES;
                model.iCloudSyncProgress = 1.f;
                acc_dispatch_main_async_safe(^{
                    [ACCToast() show:ACCLocalizedString(@"icloud_download_fail", @"从iCloud同步内容失败")];
                });
            } else {
                model.iCloudSyncProgress = process;
            }

        } completion:^(AWEAssetModel *asset) {
            @strongify(self);
            if (asset) {
                if ([self publishModel].repoMusic.music) {
                    return;
                }
                self.videoExport = IESAutoInline(ACCBaseServiceProvider(), ACCQuickAlbumExportProtocol);
                [self.videoExport handleLocationInfosForQuickAlbumVideo:locationInfos];
                AWEVideoPublishViewModel *model = [self publishModel].copy;
                model.repoUploadInfo.extraDict[@"enter_method_album"] = @"click_fast_album";
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion);
                    [self.videoExport exportVideoToEditing:@[asset] publishModel:model];
                });
            }
        }];
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)quickAlbumNeedLoadMore
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [CAKPhotoManager getAllAssetsAndResultWithType:AWEGetResourceTypeImageAndVideo
                                             sortStyle:CAKAlbumAssetSortStyleDefault
                                             ascending:NO
                                            completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
            acc_dispatch_main_async_safe(^{
                [self.quickAlbumView setQuickAlbumDatasource:[CAKAlbumAssetModel convertToStudioArray:assetModelArray]];
            });
        }];
    });
}

- (void)quickAlbumSwipeHide
{
    [self.quickAlbumView quickAlbumHasShow];
    [self hideQuickAlbum:@{@"enter_method": @"slide_down", @"event": @"fast_upload_photo_close"}];
}

#pragma mark - AWECameraFeatureButtonPassThroughViewDelegate
- (void)handleFeatureButtionPassThroughHitTest
{
    [self hideQuickAlbum:@{@"enter_method": @"blank", @"event": @"fast_upload_photo_close"} isFromPassThrough:YES];
}

#pragma mark - Util
- (void)fetchPreVisibleAssetsWithCompletion:(void (^)(NSArray<AWEAssetModel *> *assets))completion
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [CAKPhotoManager getLatestAssetCount:30
                                   sortStyle:CAKAlbumAssetSortStyleDefault
                                        type:AWEGetResourceTypeImageAndVideo
                                  completion:^(NSArray<CAKAlbumAssetModel *> *latestAssets) {
            ACCBLOCK_INVOKE(completion, [CAKAlbumAssetModel convertToStudioArray:latestAssets]);
        }];
    });
}

- (void)fetchVideoAsset:(AWEAssetModel *)assetModel progress:(void (^)(double process, NSError *error))progressHandler completion:(void (^)(AWEAssetModel *model))completion
{
    NSURL *url = [assetModel.asset valueForKey:@"ALAssetURL"];
    @weakify(self);
    [self fetchVideoAsset:assetModel options:[self optionsWithNetworkAccessAllowed:NO withProgress:nil] resultHandler:^(AVAsset * _Nullable blockAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        @strongify(self);
        BOOL isICloud = [info[PHImageResultIsInCloudKey] boolValue];
        assetModel.isFromICloud = isICloud;
        if (isICloud && !blockAsset) {
            assetModel.iCloudSyncProgress = 0.f;
            acc_dispatch_main_async_safe(^{
                [ACCToast() show:ACCLocalizedString(@"creation_icloud_download", @"正在从iCloud同步内容")];
            });
            [self fetchVideoAsset:assetModel options:[self optionsWithNetworkAccessAllowed:YES withProgress:progressHandler] resultHandler:^(AVAsset * _Nullable blockAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                assetModel.avAsset = blockAsset;
                if (blockAsset) {
                    assetModel.avAsset = blockAsset;
                    if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == AWEAssetModelMediaSubTypeVideoHighFrameRate) {
                        AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                        if (urlAsset) {
                            assetModel.avAsset = urlAsset;
                        }
                    }
                    assetModel.info = info;
                    assetModel.canUnobserveAssetModel = YES;
                    assetModel.iCloudSyncProgress = 1.f;
                    ACCBLOCK_INVOKE(completion, assetModel);
                } else {
                    assetModel.didFailFetchingiCloudAsset = YES;
                    assetModel.iCloudSyncProgress = 1.f;
                    ACCBLOCK_INVOKE(completion, nil);
                }
            }];
        } if (blockAsset) {
            assetModel.avAsset = blockAsset;
            if (ACCSYSTEM_VERSION_LESS_THAN(@"9") && assetModel.mediaSubType == AWEAssetModelMediaSubTypeVideoHighFrameRate) {
                AVURLAsset *urlAsset = [AVURLAsset assetWithURL:url];
                if (urlAsset) {
                    assetModel.avAsset = urlAsset;
                }
            }
            assetModel.info = info;
            ACCBLOCK_INVOKE(completion, assetModel);
        } else {
            AWELogToolError(AWELogToolTagRecord, @"request assets from album error");
        }
    }];
}

- (PHVideoRequestOptions *)optionsWithNetworkAccessAllowed:(BOOL)networkAccessAllowed withProgress:(void (^ __nullable)(double progress, NSError *error))progressHandler
{
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    if (@available(iOS 14.0, *)) {
        options.version = PHVideoRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    }
    options.networkAccessAllowed = networkAccessAllowed;
    if (progressHandler) {
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progressHandler(progress, error);
            });
        };
    }
    return options;
}

- (void)fetchVideoAsset:(AWEAssetModel *)assetModel
                options:(PHVideoRequestOptions *)options
           resultHandler:(void (^)(AVAsset *__nullable asset, AVAudioMix *__nullable audioMix, NSDictionary *__nullable info))resultHandle
{
    PHAsset *sourceAsset = assetModel.asset;
    self.currentId = [[PHImageManager defaultManager] requestAVAssetForVideo:sourceAsset
                                                    options:options
                                              resultHandler:^(AVAsset *_Nullable blockAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
        ACCBLOCK_INVOKE(resultHandle, blockAsset, audioMix, info);
    }];
}

- (BOOL)hasAuthorized
{
    PHAuthorizationStatus authorizationStatus = [ACCDeviceAuth acc_authorizationStatusForPhoto];
    BOOL isPHAuthorized = authorizationStatus == PHAuthorizationStatusAuthorized;
    if (@available(iOS 14.0, *)) {
        authorizationStatus = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
        if (authorizationStatus == PHAuthorizationStatusLimited) {
            isPHAuthorized = NO;
        }
    }
    return isPHAuthorized;
}

- (BOOL)currentReferCanShow
{
    return [[self publishModel].repoTrack.referString isEqualToString:@"direct_shoot"];
}

- (void)addPHPhotoLibraryObserver
{
    // 未授权状态不添加监听
    if ([self hasAuthorized]) {
        self.hasRegisterChangeObserver = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        });
    }
}

#pragma mark - PHPhotoLibraryChangeObserver
- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    [self quickAlbumNeedLoadMore];
}

#pragma mark - ACCRecordGestureServiceSubscriber

- (NSArray<UIGestureRecognizer *> *)gesturesWillAdded
{
    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickAblumSwipe:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    swipeUp.delaysTouchesBegan = YES;
    [self.viewContainer.interactionView addGestureRecognizer:swipeUp];

    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickAblumSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    swipeDown.delaysTouchesBegan = YES;
    [self.viewContainer.interactionView addGestureRecognizer:swipeDown];

    UISwipeGestureRecognizer *swipeL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickAblumSwipe:)];
    swipeL.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.viewContainer.interactionView addGestureRecognizer:swipeL];

    UISwipeGestureRecognizer *swipeR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleQuickAblumSwipe:)];
    swipeR.direction = UISwipeGestureRecognizerDirectionRight;
    [self.viewContainer.interactionView addGestureRecognizer:swipeR];
    
    return @[swipeUp, swipeDown, swipeL, swipeR];
}

- (void)handleQuickAblumSwipe:(UISwipeGestureRecognizer *)swipe
{
    if (self.focusViewModel.exposureCompensationGestureEnabled) {
        [[self viewModel] showOrHideQuickAlbum:NO];
        return;
    }
    if (UISwipeGestureRecognizerDirectionUp == swipe.direction) {
        [[self viewModel] showOrHideQuickAlbum:YES];
    } else {
        [[self viewModel] showOrHideQuickAlbum:NO];
    }
}

- (void)tapGestureDidRecognized:(UITapGestureRecognizer *)tap
{
    [[self viewModel] showOrHideQuickAlbum:NO isBlank: YES];
}

- (void)longPressGestureDidRecognized:(UILongPressGestureRecognizer *)longPress
{
    [[self viewModel] showOrHideQuickAlbum:NO isBlank: YES];
}

- (void)pinchGestureDidRecognized:(UIPinchGestureRecognizer *)pinch
{
    [[self viewModel] showOrHideQuickAlbum:NO isBlank: YES];
}

@end
