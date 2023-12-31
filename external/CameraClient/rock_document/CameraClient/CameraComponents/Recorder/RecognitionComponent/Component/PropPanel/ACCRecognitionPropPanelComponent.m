//
//  ACCExposePropPanelComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import "ACCRecognitionPropPanelComponent.h"

#import <CameraClient/ACCPropPickerViewModel.h>
#import <CameraClient/ACCPropViewModel.h>
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CameraClient/ACCRecordContainerMode.h>
#import <CameraClient/ACCRecordFlowService.h>
#import <CameraClient/ACCRecordPropService.h>
#import <CameraClient/ACCRecordSelectPropViewModel.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/AWERepoTrackModel.h>
#import <CameraClient/AWEStickerApplyHandlerContainer.h>
#import <CameraClient/AWEStickerPickerControllerCollectionStickerPlugin.h>
#import <CameraClient/AWEStickerPickerControllerFavoritePlugin.h>
#import <CameraClient/AWEStickerPickerControllerMusicPropBubblePlugin.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitInfra/ACCDeviceAuth.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <SmartScan/SSRecommendResult.h>

#import "ACCExposePanGestureRecognizer.h"
#import "ACCFlowerService.h"
#import "ACCRecognitionPropPanelView+Tray.h"
#import "ACCRecognitionPropPanelViewModel.h"
#import "ACCRecognitionService.h"
#import "ACCRecordSubmodeViewModel.h"
#import "AWERepoPropModel.h"
#import "ACCPropPickerViewModel.h"

typedef NS_ENUM(NSUInteger, ACCRecognitionPropPanelState) {
    ACCRecognitionPropPanelNone,
    ACCRecognitionPropPanelShowing,
    ACCRecognitionPropPanelHidden,
};

@interface ACCRecognitionPropPanelComponent ()<
ACCRecordSwitchModeServiceSubscriber,
ACCRecordPropServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver>

@property (nonatomic, strong) ACCRecognitionPropPanelViewModel *viewModel;

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecognitionService> recognitionService;

@property (nonatomic, strong) ACCRecognitionPropPanelView *exposePanelView;
@property (nonatomic, assign) ACCRecognitionPropPanelState propPanelState;
@property (nonatomic, strong) ACCRecordMode *recordMode;

@end

@implementation ACCRecognitionPropPanelComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, recognitionService, ACCRecognitionService)

#pragma mark - Component Lifecycle

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
    [self.propService addSubscriber:self];
}

- (void)componentDidMount
{
    [self bindViewModel];

    [self.viewModel fetchHotDataIfNeeded];
}

- (void)componentDidAppear
{
    if (self.recognitionService.stashedEffect){
        [[self recognitionService] applyProp:self.recognitionService.stashedEffect propSource:ACCPropSourceReset];
        if (self.isExists){
            [self showPanel];
        }
    }
}

#pragma mark - Private

- (void)bindViewModel
{
    @weakify(self);

    [self.viewContainer addObserver:self];

    [[[[self viewModel].propSelectionSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(IESEffectModel * _Nullable x) {
        @strongify(self);
        if ([self isShowingPanel]) {
            ACCPropPickerViewModel *propPickerViewModel = [self getViewModel:[ACCPropPickerViewModel class]];
            // prop with child or binded props propcess by prop picker panel
            BOOL isDownloadableSticker = x.fileDownloadURLs.count > 0 && x.fileDownloadURI.length > 0;
            if (x != nil && !isDownloadableSticker) {
                [propPickerViewModel selectPropFromExposePanel:x];
            }
        }
    }];

    [[[[RACObserve([self viewModel], selectedItem) skip:1] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(ACCPropPickerItem * _Nullable x) {
        @strongify(self);
        self.exposePanelView.favorButton.hidden = x.type == ACCPropPickerItemTypeHome || [x.effect forbidFavorite];
        self.recognitionService.trackModel.propIndex = [self.viewModel.propPickerDataList indexOfObject:self.viewModel.selectedItem];

    }];
    [[self viewContainer] addObserver:self];

    [[[RACObserve([self viewModel], favorStatus) takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        BOOL isFavor = [x boolValue];
        [self.exposePanelView setFavorButtonSelected:isFavor];
    }];

    [[RACObserve([self recognitionService], recordState).distinctUntilChanged takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!self.isExists){
            return;
        }
        ACCRecognitionRecorderState state = x.integerValue;
        switch (state) {
            case ACCRecognitionRecorderStateNormal:
                [self showPanelView:self.isExists animated:YES];
                break;
            case ACCRecognitionRecorderStatePausing:
            {
                [self showPanelView:NO animated:YES];
            }
                break;
            case ACCRecognitionRecorderStateFinished:
            case ACCRecognitionRecorderStateRecording:
            {
                if (self.isExists){
                    [self hidePanel];
                }
            }
                break;
        }
    }];

    [[self.recognitionService.disableRecognitionSignal.distinctUntilChanged takeUntil:self.rac_willDeallocSignal].deliverOnMainThread subscribeNext:^(RACTwoTuple*  _Nullable x) {
        @strongify(self)
        if ([x.first boolValue]){
            if ([x.last boolValue]){
                [self closeExposePanel];
            }else{
                /// hidden for recovering later
                self.exposePanelView.hidden = YES;
                if (self.isExists){
                    self.propPanelState = ACCRecognitionPropPanelHidden;
                }
            }
        }else{
            self.exposePanelView.hidden = !self.isExists;
        }
    }];
    
    [[[self.recognitionService.recognitionResultSignal takeUntil:[self rac_willDeallocSignal]] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([x isKindOfClass:SSRecommendResult.class]) {
            SSRecommendResult *recommedRes = (SSRecommendResult *)x;
            self.recognitionService.dataManager.needFallbackEffects = recommedRes.data.needFallback;
        }
    }];

    [[self.recognitionService.recognitionEffectsSignal takeUntil:self.rac_willDeallocSignal] subscribeNext:^(NSArray< IESEffectModel*>*  _Nullable x) {
        @strongify(self)
        if ([IESAutoInline(self.serviceProvider, ACCFlowerService) inFlowerPropMode]) {
            return;
        }
        self.recognitionService.dataManager.recognitionEffects = x;
        [self.viewModel updatePropPickerItems];
    }];

    [[[RACObserve(self.recognitionService, recognitionState) takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(id _Nullable x) {
        
        @strongify(self)

        if (self.recognitionService.disableRecognize){
            return;
        }
        
        if (self.recognitionService.detectResult == ACCRecognitionDetectResultQRCode) {
            return;
        }
        
        // 春节tab里不要走线上推荐道具逻辑
        if ([IESAutoInline(self.serviceProvider, ACCFlowerService) inFlowerPropMode]) {
            return;
        }
        
        ACCRecognitionState state = [x integerValue];

        /// recognize failed bcuz of network
        if (state == ACCRecognitionStateRecognizeNoNetwork){
            [ACCToast() showError:@"网络错误，请检查网络设置"];
            return;
        }

        if (state == ACCRecognitionStateRecognized ||
            state == ACCRecognitionStateRecognizeFailed) {

            // before apply recognition, reset prop for avoiding UI error
            [self.propService applyProp:nil propSource:ACCPropSourceRecognition byReason:ACCRecordPropChangeReasonEnterRecognition];
            
            [self showPanelWithCompletion:^(BOOL result) {
                [[self viewModel] applyFirstRecognition];
            }];
        }
        else if (state == ACCRecognitionStateRecognizing){
            [self.recognitionService.dataManager clearRecognitionProps];
        }
        else if (state == ACCRecognitionStateNormal ||
                 state == ACCRecognitionStateRecognizeNoNetwork){
            [self.recognitionService.dataManager clearRecognitionProps];
            [self closeExposePanel];
        }
     }];

    // update favorite list
    ACCPropPickerViewModel *propPickerViewModel = [self getViewModel:[ACCPropPickerViewModel class]];
    [[[propPickerViewModel.sendFavoriteEffectsSignal takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSArray<IESEffectModel *> * _Nullable x) {
        @strongify(self);
        [self.viewModel updateFavoriteEffects:x];
    }];
}

-(BOOL)isExists{
    return self.propPanelState != ACCRecognitionPropPanelNone;
}

#pragma mark - viewContainer Observer

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    BOOL combineModeCorrect = self.recognitionService.recordState != ACCRecognitionRecorderStateNormal; /// fixing combine mode deletes fragment causing panel showing wrongly
    if (!show || combineModeCorrect) {
        [self showPanelView:NO animated:NO];
    } else {
        [self showPanelView:self.isExists animated:NO];
    }
}

#pragma mark - UI

- (void)showPanelView:(BOOL)show animated:(BOOL)animated
{
    [self showPanelView:show animated:animated onCompletion:nil];
}

- (void)showPanelView:(BOOL)show animated:(BOOL)animated onCompletion:(void (^)(BOOL result))completion
{
    if (![ACCDeviceAuth isCameraAuth] || ![ACCDeviceAuth isMicroPhoneAuth]) {
        show = NO;
    }
    if ((!self.recordMode.isPhoto && !self.recordMode.isVideo) ||
        (self.recordMode.modeId == ACCRecordModeAudio)) {
        show = NO;
    }

    if ([self viewModel].isShowingPanel == show && self.exposePanelView.hidden == !show) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    if (!animated) {
        self.exposePanelView.hidden = !show;
        self.exposePanelView.alpha = show? 1 : 0;
        if (!show) {
            [self resetLayoutManager];
        } else {
            [self changeLayoutManager];
        }
        if (completion) {
            completion(YES);
        }
    } else {
        if (show) {
            self.exposePanelView.alpha = 1;
            self.exposePanelView.hidden = NO;
            self.exposePanelView.panelView.acc_left = self.exposePanelView.acc_width;
            [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.exposePanelView.panelView.acc_left = 0;
            } completion:^(BOOL finished) {
                if (completion) {
                    completion(YES);
                }
            }];
            [self changeLayoutManager];
        } else {
            [UIView animateWithDuration:0.1 animations:^{
                self.exposePanelView.alpha = 0;
            } completion:^(BOOL finished) {
                if (completion) {
                    completion(YES);
                }
            }];
            [self resetLayoutManager];
        }
    }
    [self viewModel].isShowingPanel = show;
    [self checkViewHiddenStatus];

    if (show){
        [self.recognitionService askingHideSwithModeView:YES];
    }
}

- (void)hideBottomBarIfNeeded
{
    /// hidding swithModeView on textMode, its totally meaningless
    if (self.recordMode.modeId == ACCRecordModeText){
        BOOL inRecognition = self.recognitionService.stashedEffect != nil;
        [self.recognitionService askingHideSwithModeView:inRecognition];
    }
}

- (void)checkViewHiddenStatus
{
    if (self.viewModel.isShowingPanel) {
        [self viewContainer].propPanelType = ACCRecordPropPanelRecognition;
    } else if (self.viewContainer.propPanelType == ACCRecordPropPanelRecognition) {
        self.viewContainer.propPanelType = ACCRecordPropPanelNone;
    } else {
        return;
    }
    
    [self viewContainer].propPanelType = self.viewModel.isShowingPanel ? ACCRecordPropPanelRecognition : ACCRecordPropPanelNone;
    if (!self.viewModel.isShowingPanel &&
        [self propViewModel].propPanelStatus != ACCPropPanelDisplayStatusShow &&
        ![self viewContainer].itemsShouldHide) {
        [self selectPropViewModel].selectPropDisplayType = ACCRecordSelectPropDisplayTypeFadeShow;
    } else {
        [self selectPropViewModel].selectPropDisplayType = ACCRecordSelectPropDisplayTypeHidden;
    }
}

- (void)changeLayoutManager
{
    [self propService].propApplyHanderContainer.layoutManager = self.exposePanelView;
    AWEStickerPickerControllerCollectionStickerPlugin *collectionPlugin = [[self propService].propPickerViewController.plugins acc_match:^BOOL(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[AWEStickerPickerControllerCollectionStickerPlugin class]];
    }];
    collectionPlugin.layoutManager = self.exposePanelView;
}

- (void)resetLayoutManager
{
    [self propService].propApplyHanderContainer.layoutManager = nil;
    AWEStickerPickerControllerCollectionStickerPlugin *collectionPlugin = [[self propService].propPickerViewController.plugins acc_match:^BOOL(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[AWEStickerPickerControllerCollectionStickerPlugin class]];
    }];
    collectionPlugin.layoutManager = [self propService].propPickerViewController;
}

- (BOOL)isShowingPanel
{
    return (self.exposePanelView.superview != nil) && (self.exposePanelView.hidden == NO) && (self.exposePanelView.alpha == 1) && ([self propService].propApplyHanderContainer.layoutManager == self.exposePanelView);
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (BOOL)needSaveRestoredPropModeId:(NSInteger)modeId
{
    return ACCRecordModeMV == modeId || ACCRecordModeLive == modeId || ACCRecordModeText == modeId;
}

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    self.recordMode = mode;

    if (!self.isExists){
        return;
    }
    [self.recognitionService updateRecordMode:mode];

    if ([self needSaveRestoredPropModeId:oldMode.modeId]) {

        /// recovery recognition state
        [self.recognitionService recoverRecognitionStateIfNeeded];
    }


    if (!self.recognitionService.disableRecognize){
        [self showPanelView:self.isExists animated:NO];
    }else{
        [self showPanelView:NO animated:YES];
    }

    [self hideBottomBarIfNeeded];
    [self updatePanelTintColor];
}

- (void)updatePanelTintColor
{
    if (!self.viewModel.homeItem){
        return;
    }
    if (self.recordMode.modeId == ACCRecordModeTakePicture) {
        self.exposePanelView.panelView.homeTintMode = ACCScrollPropPickerHomeTintModePicture;
    } else if (self.recordMode.modeId == ACCRecordModeStory) {
        self.exposePanelView.panelView.homeTintMode = ACCScrollPropPickerHomeTintModeStory;
    } else {
        self.exposePanelView.panelView.homeTintMode = ACCScrollPropPickerHomeTintModeVideo;
    }
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceDidChangePropPickerDataSource:(AWEStickerPicckerDataSource *)dataSource
{
    [self recognitionService].dataManager.propPickerDataSource = dataSource;
}

- (void)propServiceDidChangePropPickerModel:(AWEStickerPickerModel *)model
{
    [self recognitionService].dataManager.propPickerModel = model;
    AWEStickerPickerControllerFavoritePlugin *favoritePlugin = [[self propService].propPickerViewController.plugins acc_match:^BOOL(id<AWEStickerPickerControllerPluginProtocol>  _Nonnull item) {
        return [item isKindOfClass:[AWEStickerPickerControllerFavoritePlugin class]];
    }];
    favoritePlugin.favoriteObserver = [self viewModel];
}

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{

}

- (void)propServiceDidSelectBgPhoto:(UIImage *)bgPhoto photoSource:(NSString * _Nullable)photoSource
{
    // 选择绿幕背景照片后关闭道具面板
    if (photoSource != nil) {
        [self hidePanel];
    }
}

- (void)propServiceDidSelectBgPhotos:(NSArray<UIImage *> *)bgPhotos
{
    if (bgPhotos != nil) {
        [self hidePanel];
    }
}

- (void)propServiceDidSelectBgVideo:(NSURL *)bgVideoURL videoSource:(NSString * _Nullable)videoSource
{
    // 选择绿幕背景视频后关闭道具面板
    if (videoSource != nil) {
        [self hidePanel];
    }
}

#pragma mark - Getter && setter

- (ACCRecognitionPropPanelViewModel *)viewModel
{
    if (_viewModel == nil) {
        _viewModel = [self getViewModel:[ACCRecognitionPropPanelViewModel class]];
        @weakify(self);
        _viewModel.cameraServiceBlock = ^id<ACCCameraService> _Nonnull{
            @strongify(self);
            return self.cameraService;
        };
    }
    return _viewModel;
}

- (ACCRecordSelectPropViewModel *)selectPropViewModel
{
    ACCRecordSelectPropViewModel *selectPropViewModel = [self getViewModel:[ACCRecordSelectPropViewModel class]];
    NSAssert(selectPropViewModel, @"should not be nil");
    return selectPropViewModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:[ACCPropViewModel class]];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (void)showPanel
{
    [self showPanelWithCompletion:nil];
}

- (void)showPanelWithCompletion:(void (^)(BOOL result))completion
{
    /// do nothing
    if ([self recognitionService].disableRecognize) {
        return;
    }
    [self setupExposePanelViewIfNeeded];
    UIView *switchLengthView = [self.viewContainer.layoutManager viewForType:ACCViewTypeSwitchSubmodeView];
    if (!switchLengthView.hidden) {
        self.exposePanelView.trayViewOffset = [self.viewContainer.layoutManager viewForType:ACCViewTypeSwitchSubmodeView].acc_height;
    } else {
        self.exposePanelView.trayViewOffset = 0;
    }
    [self.viewModel fetchHotDataIfNeeded];
    [self.viewModel fetchFavoriteEffectsIfNeed];

    self.propPanelState = ACCRecognitionPropPanelShowing;
    [self showPanelView:YES animated:YES onCompletion:completion];
}

- (void)hidePanel
{
    if (!self.isExists){
        return;
    }
    self.propPanelState = ACCRecognitionPropPanelHidden;
    [self showPanelView:NO animated:YES];
}

- (void)closeExposePanel {

    if (!self.isExists){
        return;
    }
    self.propPanelState = ACCRecognitionPropPanelNone;
    ACCRecordSubmodeViewModel *submodeViewModel = [self getViewModel:[ACCRecordSubmodeViewModel class]];
    // submodeViewModel close will case engine tap when mode reset, do not tap twice
    if (submodeViewModel.modeIndex == submodeViewModel.containerMode.defaultIndex) {
        [ACCTapticEngineManager tap];
    }
    [self showPanelView:NO animated:YES];
    [[self viewModel] cancelPropSelection];
//    [submodeViewModel close];
    [self.viewContainer showItems:YES animated:NO];
    [self.recognitionService askingHideSwithModeView:NO];
    self.viewContainer.switchModeContainerView.collectionView.transform = CGAffineTransformMakeTranslation(0, -10);
    self.viewContainer.switchModeContainerView.collectionView.alpha = 0;
    self.viewContainer.switchModeContainerView.cursorView.alpha = 0;
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.viewContainer.switchModeContainerView.collectionView.transform = CGAffineTransformIdentity;
        self.viewContainer.switchModeContainerView.collectionView.alpha = 1;
        self.viewContainer.switchModeContainerView.cursorView.alpha = 1;
        self.exposePanelView.backgroundView.transform = CGAffineTransformMakeTranslation(0, 30);
        self.exposePanelView.closeButton.transform = CGAffineTransformMakeScale(0.7, 0.7);
        self.exposePanelView.closeButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.exposePanelView.backgroundView.transform = CGAffineTransformIdentity;
        self.exposePanelView.closeButton.transform = CGAffineTransformIdentity;
        self.exposePanelView.closeButton.alpha = 1;
    }];
}

- (void)setupExposePanelViewIfNeeded
{
    if (_exposePanelView == nil) {
        _exposePanelView = [[ACCRecognitionPropPanelView alloc] init];
        _exposePanelView.moreButton.hidden = YES;
        _exposePanelView.alpha = 0;
        _exposePanelView.panelView.panelViewMdoel = self.viewModel;
        _exposePanelView.exposePanGestureRecognizer.innerTouchDelegateView = [self.viewContainer.layoutManager viewForType:ACCViewTypeCaptureAnimation];
        @weakify(self);
        _exposePanelView.closeButtonClickCallback = ^{
            @strongify(self);
            [self closeExposePanel];
            [self.recognitionService resetRecognition];
            [self trackClose];
        };
        _exposePanelView.favorButtonClickCallback = ^{
            @strongify(self);
            [[self viewModel] changeFavorStatus];
        };
        _exposePanelView.onTrayViewChanged = ^(UIView *trayView) {
            @strongify(self);
            [self.viewContainer.layoutManager addSubview:trayView viewType:ACCViewTypeExposePropPanel];
        };
        [[self viewContainer].rootView addSubview:_exposePanelView];
        [_exposePanelView setShowFavorAndMoreButton:NO];
        _exposePanelView.recordButtonTop = [[self viewContainer].layoutManager.guide recordButtonCenterY] - 40;
        _exposePanelView.frame = CGRectMake(0, 0, [self viewContainer].rootView.acc_width, [self viewContainer].rootView.acc_height);

        [self updatePanelTintColor];
    }
}

#pragma mark - Track

- (void)trackClose
{
    [ACCTracker() trackEvent:@"close_trigger_reality"
                      params:self.trackingParams];
}

- (ACCRecordViewControllerInputData *)inputData
{
    return [[self getViewModel:ACCRecorderViewModel.class] inputData];
}

- (NSDictionary *)trackingParams
{
    AWERepoContextModel *contextModel = [self.inputData.publishModel extensionModelOfClass:AWERepoContextModel.class];
    AWERepoTrackModel *trackModel = [self.inputData.publishModel extensionModelOfClass:AWERepoTrackModel.class];

    return @{
        @"enter_method": @"cross_button",
        @"shoot_way": trackModel.referString?: @"",
        @"creation_id":[contextModel createId] ?: @"",
        @"record_mode": trackModel.tabName ?: @"",
        @"enter_from": @"video_shoot_page",
        @"reality_id": self.recognitionService.trackModel.realityId ?: @"",
    };
}

@end
