//
//  ACCStickerPannelComponent.m
//  Pods
//
//  Created by chengfei xiao on 2019/10/22.
//

#import "AWERepoContextModel.h"
#import "ACCStickerPannelComponent.h"

#import "AWEMusicStickerRecommendManager.h"

#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCStickerPannelViewModel.h"
#import "ACCStickerPannelLoggerImpl.h"
#import "AWEVideoEditStickersViewController.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCStickerGestureComponentProtocol.h"

#import "ACCInfoStickerServiceProtocol.h"

#import "AWEInformationStickerDataManager.h"
#import "ACCAlbumImageInformationStickerDataManager.h"
#import "ACCStickerPannelFilterImpl.h"
#import <CreativeKit/ACCFontProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCRepoKaraokeModelProtocol.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCVideoEditFlowControlService.h"
#import "AWEVideoPublishResponseModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCStudioGlobalConfig.h"
#import "ACCEditImageAlbumMixedProtocolD.h"

@interface ACCStickerPannelComponent () <
AWEVideoEditStickersVCDelegate,
ACCStickerPannelAnimationVCDelegate,
ACCEditSessionLifeCircleEvent,
ACCStickerPannelFilterDataSource,
UIGestureRecognizerDelegate
>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) UIView *stickerBgView;
@property (nonatomic, strong) AWEVideoEditStickersViewController *stickerViewController;

@property (nonatomic, weak) id<ACCStickerGestureComponentProtocol> stickerGestureComponent;

@property (nonatomic, weak) id<ACCInfoStickerServiceProtocol> infoStickerService;

@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowControlService;

@property (nonatomic, strong) id<ACCStickerPannelLogger> pannelLogger;
@property (nonatomic, strong) ACCStickerPannelViewModel *viewModel;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGRect gestureResponseArea;
@property (nonatomic, assign) BOOL isVerticalPan;

@end


@implementation ACCStickerPannelComponent
@synthesize stickerBgView = _stickerBgView;
@synthesize stickerViewController = _stickerViewController;

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, infoStickerService, ACCInfoStickerServiceProtocol)
IESAutoInject(self.serviceProvider, flowControlService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, stickerGestureComponent, ACCStickerGestureComponentProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCStickerPanelServiceProtocol), self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
}

- (void)loadComponentView {
    [self.viewContainer addToolBarBarItem:[self barItem]];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_bindViewModel];
}

- (void)componentWillAppear
{
    [self configStickerPanGesture:[self.viewContainer gestureView]];
}

#pragma mark Getter

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panShowStickerPanel:)];
        _panGesture.cancelsTouchesInView = NO;
        _panGesture.maximumNumberOfTouches = 1;
        _panGesture.delaysTouchesBegan = YES;
        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (void)configStickerPanGesture:(UIView *)view
{
    CGFloat width = view.frame.size.width;
    CGFloat height = view.frame.size.height;
    [self addStickerPanelGestureForView:view gestureResponseArea:CGRectMake(0, 0, width, height)];
}

- (void)addStickerPanelGestureForView:(nonnull UIView *)view gestureResponseArea:(CGRect)gestureResponseArea
{
    self.gestureResponseArea = gestureResponseArea;
    [view addGestureRecognizer:self.panGesture];
}

- (BOOL)enableStickerPan
{
    return ACCConfigBool(kConfigBool_tools_edit_sticker_panel_swipe_up);
}

- (BOOL)showStickerPanelShouldBegin {
    if([[self stickerGestureComponent].stickerGestureController hitTargetStickerWithGesture:self.panGesture deSelected:NO]) {
        return NO;
    }
    return YES;
}

- (void)panShowStickerPanel:(UIPanGestureRecognizer *)gestureRecognizer
{
    if(![self enableStickerPan]) {
        return;
    }
    UIView *panView = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:panView];
    if (!CGRectEqualToRect(self.gestureResponseArea,CGRectZero)) {
        if (location.x < self.gestureResponseArea.origin.x || location.x > self.gestureResponseArea.size.width ||
            location.y < self.gestureResponseArea.origin.y || location.y > self.gestureResponseArea.size.height) {
            return;
        }
    }
    
    double velocityX = [gestureRecognizer velocityInView:panView].x;
    double velocityY = [gestureRecognizer velocityInView:panView].y;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            if (fabs(velocityY) >= fabs(velocityX)) {
                self.isVerticalPan = YES;
                [self handleStartVerticalPan];
            } else {
                self.isVerticalPan = NO;
            }
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateEnded: {
            if(self.isVerticalPan && (velocityY < 0)) {
                [self handleVerticalPanWithOffset:0 velocity:0 finished:NO];
            } else {
                [self handleCancelledVeritcalPan];
            }
        }
        default:
            [self handleCancelledVeritcalPan];
            break;
    }
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    ACCBaseInformationStickerDataManager *dataManager = nil;
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        dataManager = [ACCAlbumImageInformationStickerDataManager defaultManager];
    } else {
        dataManager = [AWEInformationStickerDataManager defaultManager];
    }
    dataManager.logger = self.pannelLogger;
    [dataManager downloadStickersWithCompletion:^(BOOL downloadSuccess) {}];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* item = [[ACCBarItem alloc] init];
    item.title = config.title;
    item.location = config.location;
    item.imageName = config.imageName;
    item.itemId = ACCEditToolBarInfoStickerContext;
    item.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    item.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self trackEnterPanelWithEntrance:nil];
        [self.viewContainer.topRightBarItemContainer resetFoldState];
        [self showStickerPannel];
    };
    item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeSticker];
    return item;
}


- (AWEVideoEditStickersViewController *)stickerViewController
{
    if (!_stickerViewController) {
        _stickerViewController = [[AWEVideoEditStickersViewController alloc] init];
        _stickerViewController.containerVC = self.rootVC;
        _stickerViewController.animationView = self.viewContainer.containerView;
        _stickerViewController.delegate = self;
        _stickerViewController.transitionDelegate = self;
        _stickerViewController.enableEmojiSticker = YES;
        _stickerViewController.logger = self.pannelLogger;
        
        ACCStickerPannelUIConfig *uiConfig = [ACCStickerPannelUIConfig new];
        uiConfig.slidingTabbarViewButtonTextNormalFont = [ACCFont() acc_boldSystemFontOfSize:15];
        uiConfig.slidingTabbarViewButtonTextSelectFont = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        uiConfig.stickerCollectionViewCellInsets = UIEdgeInsetsMake(3.5, 3.5, 3.5, 3.5);

        _stickerViewController.uiConfig = uiConfig;
        
        ACCStickerPannelFilterImpl *filter = [ACCStickerPannelFilterImpl new];
        filter.repository = self.repository;
        filter.dataSource = self;
        _stickerViewController.pannelFilter = filter;
    }
    return _stickerViewController;
}

- (id<ACCStickerPannelLogger>)pannelLogger {
    if (!_pannelLogger) {
        ACCStickerPannelLoggerImpl *logger = [ACCStickerPannelLoggerImpl new];
        logger.repository = self.repository;
        _pannelLogger = logger;
    }
    return _pannelLogger;
}

- (UIView *)stickerBgView
{
    if (!_stickerBgView) {
        _stickerBgView = [[UIView alloc] initWithFrame:self.rootVC.view.bounds];
        [_stickerBgView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeStickerPannel)]];
    }
    return _stickerBgView;
}

- (void)removeStickerPannelWithAlphaAnimated:(BOOL)animated
{
    [self removeStickerPannelWithAlphaAnimated:animated selectedSticker:nil];
}

- (void)removeStickerPannelWithAlphaAnimated:(BOOL)animated selectedSticker:(nullable ACCStickerSelectionContext *)selectedSticker
{
    
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"stickerPanel"];

    self.rootVC.view.isAccessibilityElement = NO;
    [self.stickerBgView removeFromSuperview];
    [self.viewModel willDismissStickerPanel:selectedSticker];
    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        [self.viewContainer.topRightBarItemContainer resetFoldState];
    }
    if (animated) {
        @weakify(self);
        [_stickerViewController removeAlphaWithCompletion:^{
            @strongify(self);
            if (selectedSticker) {
                [[self viewModel] didDismissStickerPanelWithSelectedSticker:selectedSticker];
            }
            [self configPannelVC:YES];
        }];
    } else {
        @weakify(self);
        [_stickerViewController removeWithCompletion:^{
            @strongify(self);
            if (selectedSticker) {
                [[self viewModel] didDismissStickerPanelWithSelectedSticker:selectedSticker];
            }
            [self configPannelVC:YES];
        }];
    }
}

- (void)removeStickerPannel
{
    [self removeStickerPannelWithAlphaAnimated:NO];
}

- (void)showStickerPannel
{
    [self showStickerPannelWithAlphaAnimated:NO];
}

- (void)showStickerPannelWithAlphaAnimated:(BOOL)alphaAnimated
{
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"stickerPanel"];
    
    self.repository.repoContext.isStickerEdited = YES;
    [[AWEMusicStickerRecommendManager sharedInstance] fetchRecommendMusicWithRepository:self.repository
                                                                               callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
        if (error) {
            AWELogToolError2(@"edit", AWELogToolTagEdit, @"prefetch recommend music failed: %@", error);
        }
    }];

    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    if (self.repository.repoContext.isIMRecord) {
        referExtra[@"scene_id"] = @(1004);
    }
    
    [self.rootVC.view addSubview:self.stickerBgView];
    [[self viewModel] willShowStickerPanel];
    
    ACCStickerPannelDataConfig *dataConfig = [[ACCStickerPannelDataConfig alloc] init];
    dataConfig.zipURI = self.repository.repoMusic.zipURI ? : @"";
    dataConfig.creationId = self.repository.repoContext.createId;
    dataConfig.trackParams = self.repository.repoTrack.commonTrackInfoDic;
    self.stickerViewController.dataConfig = dataConfig;
    
    if (alphaAnimated) {
        [self.stickerViewController showAlphaWithCompletion:nil];
    } else {
        [self.stickerViewController showWithCompletion:nil];
    }
}

- (void)handleStartVerticalPan
{
    if ([self editService].imageAlbumMixed) {
        [[self editService].imageAlbumMixed setImagePlayerScrollEnable:NO];
    }
}

- (void)handleCancelledVeritcalPan
{
    if ([self editService].imageAlbumMixed) {
        [[self editService].imageAlbumMixed setImagePlayerScrollEnable:YES];
    }
}

//TODO @Shichen Peng
- (void)handleVerticalPanWithOffset:(CGFloat)offset velocity:(CGFloat)velocity finished:(BOOL)finished
{
    if (!self.isMounted) {
        return;
    }
    [self trackEnterPanelWithEntrance:@"slide_up"];
    [self.viewContainer.topRightBarItemContainer resetFoldState];
    [self showStickerPannel];
}

- (void)configPannelVC:(BOOL)show
{
    self.stickerBgView.hidden = !show;
    self.stickerViewController.view.hidden = !show;
}

- (NSInteger)addSearchInfoSticker:(ACCAddInfoStickerContext *)context
{
    if (context.source == ACCInfoStickerSourceThirdParty) {
        return [self.viewModel handleSelectThirdPartySticker:context.thirdPartyModel];
    } else {
        return [self.viewModel handleSelectSticker:context.stickerModel fromTab:context.tabName];
    }
}

- (BOOL)canOpenLiveSticker
{
    return self.flowControlService.uploadParamsCache.settingsParameters.hasLive.boolValue && [ACCStudioGlobalConfig() shouldKeepLiveMode];
}

#pragma mark - AWEVideoEditStickersVCDelegate

- (void)stickerViewController:(AWEVideoEditStickersViewController *)videoEditStickersVC didSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName downloadTrigger:(dispatch_block_t)downloadTrigger {
    if ([self.viewModel handleSelectSticker:sticker fromTab:tabName]) {
        // sticker is handled, return directly
        return;
    }
    
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        if (self.stickerService.stickerCount >= ACCConfigInt(kConfigInt_album_image_max_sticker_count)) {
            [ACCToast() show: ACCLocalizedString(@"infosticker_maxsize_limit_toast", @"贴纸个数已达上限")];
            return;
        }
    } else if ([self p_totalStickers] >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        [ACCToast() show: ACCLocalizedString(@"infosticker_maxsize_limit_toast", @"贴纸个数已达上限")];
        // sticker is over loaded, return directly
        return;
    }
    
    // otherwise download info sticker
    ACCBLOCK_INVOKE(downloadTrigger);
}

- (void)stickerViewController:(AWEVideoEditStickersViewController *)videoEditStickersVC didSelectThirdPartySticker:(IESThirdPartyStickerModel *)sticker fromTab:(NSString *)tabName downloadTrigger:(dispatch_block_t)downloadTrigger
{
    if ([self.viewModel handleSelectThirdPartySticker:sticker]) {
        return;
    }
    
    if ([self p_totalStickers] >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        [ACCToast() show: ACCLocalizedString(@"infosticker_maxsize_limit_toast", @"贴纸个数已达上限")];
        return;
    }
    
    ACCBLOCK_INVOKE(downloadTrigger);
}

#pragma mark - ACCStickerPannelAnimationVCDelegate
- (void)stickerPannelVCDidDismiss {
    self.rootVC.view.isAccessibilityElement = NO;
    [self.stickerBgView removeFromSuperview];
    [[self viewModel] willDismissStickerPanel:nil];
    [[self viewModel] didDismissStickerPanelWithSelectedSticker:nil];
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"stickerPanel"];
}

#pragma mark - private methods

- (void)p_bindViewModel
{
    @weakify(self);
    self.viewModel.configureGestureWithView = ^(UIView *view){
        @strongify(self);
        [self configStickerPanGesture:view];
    };
    [[[[self stickerService] willStartEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id _Nullable x) {
        @strongify(self);
        self.panGesture.enabled = NO;
    }];
    [[[[self stickerService] didFinishEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id _Nullable x){
        @strongify(self);
        self.panGesture.enabled = YES;
    }];
}

- (NSInteger)p_totalStickers
{
    return self.stickerService.infoStickerCount;
}

#pragma mark - getter,should optimize

- (UIViewController *)rootVC
{
    return self.controller.root;
}

#pragma mark - view model

- (ACCStickerPannelViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCStickerPannelViewModel alloc] init];
        @weakify(self);
        _viewModel.dismissPanelBlock = ^(ACCStickerSelectionContext *ctx, BOOL animated) {
            @strongify(self);
            [self removeStickerPannelWithAlphaAnimated:animated selectedSticker:ctx];
        };
    }
    return _viewModel;
}

-(id<ACCStickerServiceProtocol>)stickerService
{
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(gestureRecognizer == self.panGesture && ![self showStickerPanelShouldBegin]) {
        return NO;
    }
    if([[self stickerService] respondsToSelector:@selector(isSelectedSticker:)]) {
        if([[self stickerService] isSelectedSticker:gestureRecognizer]) {
            return NO;
        }
    }
    return YES;
 }

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - Track

- (void)trackEnterPanelWithEntrance:(NSString *)entrance
{
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    if (self.repository.repoContext.isIMRecord) {
        referExtra[@"scene_id"] = @(1004);
    }
    if(entrance) {
        referExtra[@"enter_method"] = entrance;
    }
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromUnknown) {
        [referExtra addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
        id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        [referExtra addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
        referExtra[@"from_parent_id"] = self.repository.repoUploadInfo.extraDict[@"from_parent_id"];
        referExtra[@"is_groot_new"] = self.repository.repoUploadInfo.extraDict[@"is_groot_new"];
        BOOL grootShow = [ACCCache() boolForKey:@"kAWENormalVideoEditGrootStickerBubbleShowKey"];
        referExtra[@"is_groot_toast_show"]  = grootShow ? @1 : @0;
        [ACCTracker() trackEvent:@"click_prop_entrance" params:[referExtra copy] needStagingFlag:NO];
    }
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIM) {
        [referExtra addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
        id<ACCRepoKaraokeModelProtocol> repoKaraokeModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        [referExtra addEntriesFromDictionary:([repoKaraokeModel.trackParams copy] ?: @{})];
        referExtra[@"from_parent_id"] = self.repository.repoUploadInfo.extraDict[@"from_parent_id"];
        referExtra[@"is_groot_new"] = self.repository.repoUploadInfo.extraDict[@"is_groot_new"];
        BOOL grootShow = [ACCCache() boolForKey:@"kAWENormalVideoEditGrootStickerBubbleShowKey"];
        referExtra[@"is_groot_toast_show"]  = grootShow ? @1 : @0;
        [ACCTracker() trackEvent:@"im_click_prop_entrance" params:[referExtra copy] needStagingFlag:NO];
    }
}

@end
