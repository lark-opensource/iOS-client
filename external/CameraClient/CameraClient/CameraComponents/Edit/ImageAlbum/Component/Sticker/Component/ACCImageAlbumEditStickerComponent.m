//
//  ACCImageAlbumEditStickerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/25.
//

#import "AWERepoContextModel.h"
#import "ACCImageAlbumEditStickerComponent.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerContainerView+CameraClient.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import "ACCStickerLoggerImpl.h"
#import "ACCImageAlbumEditStickerHandler.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumData.h"
#import "ACCStickerBizDefines.h"
#import "ACCStickerLimitEdgeView.h"
#import "ACCStickerContainerView+ACCImageAlbumSerialization.h"
#import "ACCImageAlbumEditStickerViewModel.h"
#import "ACCStickerHandler+Private.h"
#import "ACCImageAlbumStickerServiceImpl.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>

#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import "ACCVideoEditFlowControlService.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "ACCPublishServiceProtocol.h"
#import "ACCPublishServiceMessage.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCStickerContainerView+CameraClient.h"

static NSInteger const ACCImageAlbumEditStickerComponentContainerTag= 17892239;

@interface ACCImageAlbumEditStickerComponent ()<
ACCStickerServiceSubscriber,
ACCStickerContainerDelegate,
ACCEditImageAlbumMixedMessageProtocolD,
ACCVideoEditFlowControlSubscriber,
ACCPublishServiceMessage
>

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, strong) ACCStickerContainerView *containerView;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) ACCImageAlbumEditStickerViewModel *viewModel;
@property (nonatomic, strong) ACCImageAlbumStickerServiceImpl *stickerService;

@property (nonatomic, weak) id<ACCLyricsStickerServiceProtocol> lyricsStickerService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;


@property (nonatomic, strong) ACCImageAlbumEditStickerHandler *stickerHandler;

@property (nonatomic, strong) ACCImageAlbumItemModel *imageAlbumItem;
@property (nonatomic, strong) id<ACCVideoEditFlowControlService> flowService;

@property (nonatomic, assign) BOOL isDraftFirstAppear;

@end

@implementation ACCImageAlbumEditStickerComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, lyricsStickerService, ACCLyricsStickerServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)

- (void)dealloc
{
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCStickerServiceProtocol),
                                   self.stickerService);
}

#pragma mark - Life Cycle

- (void)componentDidMount
{
    self.isDraftFirstAppear = YES;

    [self configLogger];
    
    [self bindViewModel];
    
    [self addObserver];
    
    REGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (void)componentDidAppear
{
    const BOOL isDraftOrBackUp = self.publishModel.repoDraft.isDraft || self.publishModel.repoDraft.isBackUp;
    if (self.isDraftFirstAppear && isDraftOrBackUp) {
        [self.stickerService resetStickerInPlayer];
        self.isDraftFirstAppear = NO;
    }
    ACCBLOCK_INVOKE([self.stickerPanelService configureGestureWithView], [self.editService mediaContainerView]);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    self.stickerService.publishModel = [self publishModel];
    self.stickerService.editService = self.editService;
    
    [self.flowService addSubscriber:self];
    [[self editService] addSubscriber:self];
}

- (void)addObserver
{
    @weakify(self);
    [[[[[NSNotificationCenter defaultCenter]
     rac_addObserverForName:kAWEVideoNewPublishViewControllerWillDismissNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     deliverOnMainThread]
     subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self.stickerService resetStickerInPlayer];
    }];
}

#pragma mark - sticker handler
- (ACCImageAlbumEditStickerHandler *)stickerHandler {
    if (!_stickerHandler) {
        _stickerHandler = [ACCImageAlbumEditStickerHandler new];
    }
    
    return _stickerHandler;
}

#pragma mark - Public Methods

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (AWEVideoPublishViewModel *)publishModel {
    return self.viewModel.inputData.publishModel;
}

- (ACCImageAlbumEditStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCImageAlbumEditStickerViewModel.class];
    }
    return _viewModel;
}

#pragma mark - Private Methods

- (void)configLogger
{
    ACCStickerLoggerImpl *logger = [ACCStickerLoggerImpl new];
    logger.publishModel = self.publishModel;
    self.stickerService.compoundHandler.logger = logger;
}

- (void)setCurrentRootView:(UIView *)rootView
          stickerContainer:(ACCStickerContainerView *)stickerContainer
     stickerContainerIndex:(NSInteger)stickerContainerIndex
{
    self.containerView = stickerContainer;
    
    ACCImageAlbumItemModel *oneAlbum = self.publishModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems[stickerContainerIndex];
    self.imageAlbumItem = oneAlbum;
    
    [self.stickerService resetStickerContainer];
    self.stickerService.compoundHandler.uiContainerView = rootView;
}

- (void)bindViewModel
{
    [self.editService.imageAlbumMixed addSubscriber:self];
    @weakify(self);
    [[[self.stickerPanelService willShowStickerPanelSignal] deliverOnMainThread] subscribeNext:^(_Nullable id x){
        @strongify(self);
        [[self editService].imageAlbumMixed setImagePlayerScrollEnable:NO];
    }];
    [[[self.stickerPanelService willDismissStickerPanelSignal] deliverOnMainThread] subscribeNext:^(_Nullable id x){
        @strongify(self);
        [[self editService].imageAlbumMixed setImagePlayerScrollEnable:YES];
    }];
}

- (void)readyForPublish {
    [self.stickerService deselectAllSticker];

    //1，text sticker info
    [self setStickersForPublish];
}

- (void)saveCurrentStickersToPublishModel
{
    self.imageAlbumItem.stickerInfo.textStickers = [self.containerView stickerStorageModelsWithTypeId:ACCStickerTypeIdText];
    // 记录交互贴纸
    [self.stickerService addInteractionStickerInfosForImageItem:self.imageAlbumItem inContainer:self.containerView];
}

- (void)setStickersForPublish
{
    self.stickerService.simStickerContainer = [self createSimStickerContainer];
    
    [self saveCurrentStickersToPublishModel];
    [self.stickerService setStickersForPublish];
    [self.stickerService addInteractionStickerInfosForImageItem:self.imageAlbumItem inContainer:self.containerView];
    
    self.stickerService.simStickerContainer = nil;
}

- (NSInteger)hierarchyLevel
{
    return AWEStickerHierarchyPOISticker;
}

#pragma mark - ACCVideoEditFlowControlSubscriber

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self readyForPublish];
    [self.stickerService finish];
}

-(void)willSwitchImageAlbumEditModeWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self saveCurrentStickersToPublishModel];
}

- (void)synchronizeRepositoryWithEditFlowService:(id<ACCVideoEditFlowControlService>)service
{
    [self saveCurrentStickersToPublishModel];
}

#pragma mark - ACCPublishServiceMessage

- (void)publishServiceWillStart
{
    [self.stickerService finish];
    [self readyForPublish];
}

- (void)publishServiceWillSaveDraft
{
    [self.stickerService finish];
    [self readyForPublish];
}


#pragma mark - Sticker Container Delegate

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureStarted:(UIGestureRecognizer *)gesture onView:(UIView *)targetView
{
    self.publishModel.repoContext.isStickerEdited = YES;
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"stickerGesture"];
}

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer gestureEnded:(UIGestureRecognizer *)gesture onView:(UIView *)targetView
{
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed)  startAutoPlayWithKey:@"stickerGesture"];
}

- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer gesture:(UIGestureRecognizer *)gesture
{
    BOOL hasStickerSelected = NO; // tap blank only do deselecte
    for (ACCStickerViewType sticker in stickerContainer.allStickerViews) {
        if (ACCDynamicCast(sticker, ACCBaseStickerView).isSelected) {
            hasStickerSelected = YES;
            break;
        }
    }
    
    if (!hasStickerSelected && [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isTextStickerShortcutEnabled]) {
        [self.stickerService startQuickTextInput];
        return YES;
    }
    return NO;
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    // 预加载贴纸信息
    [ACCCustomFont() prefetchFontEffects];
}

#pragma mark - ACCEditImageAlbumMixedMessageProtocol

- (void)onCurrentImageEditorChanged:(NSInteger)currentIndex
{
    [self saveCurrentStickersToPublishModel];
    [self updateCurrentStickerContainerWithImageIndex:currentIndex];
}

- (void)onImagePlayerWillScrollToIndex:(NSInteger)targetIndex withAnimation:(BOOL)withAnimation isByAutoTimer:(BOOL)isByAutoTimer
{
    [self.stickerService deselectAllSticker];
}

- (void)onImageEditorRecoveredAtIndex:(NSInteger)index
                          contentView:(UIView *)contentView
                            imageItem:(ACCImageAlbumItemModel *)imageItemModel
                       imageLayerSize:(CGSize)imageLayerSize
               originalImageLayerSize:(CGSize)originalImageLayerSize;
{
    CGRect playerFrame = CGRectMake(0, 0,
                                    self.editService.mediaContainerView.originalPlayerFrame.size.width,
                                    self.editService.mediaContainerView.originalPlayerFrame.size.height);
    CGRect containerFrame = contentView.bounds;
    
    ACCVideoEditStickerContainerConfig *config = [[ACCVideoEditStickerContainerConfig alloc] init];
    [config changeAlbumImagePluginsWithMaterialSize:imageLayerSize];
    config.editStickerService = self.editService.sticker;
    config.stickerHierarchyComparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if ([obj1 integerValue]< [obj2 integerValue]) {
            return NSOrderedAscending;
        } else if ([obj1 integerValue] > [obj2 integerValue]){
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
    config.ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    [config updateMusicCoverWithMusicModel:self.publishModel.repoMusic.music];
    if (self.publishModel.repoContext.isIMRecord) {
        [config removePreviewViewPlugin];
    }
    
    ACCStickerContainerView *containerView = [[ACCStickerContainerView alloc] initWithFrame:containerFrame config:config];
    [self.stickerHandler.allStickerContainers addObject:containerView];
    containerView.delegate = self;
    containerView.hierarchy = [self hierarchyLevel];
    [containerView configWithPlayerFrame:playerFrame allowMask:YES];
    containerView.shouldHandleGesture = YES;
    containerView.tag = ACCImageAlbumEditStickerComponentContainerTag;
    
    containerView.mediaActualSize = originalImageLayerSize;
    
    [contentView addSubview:containerView];
    
    ACCImageAlbumItemModel *oneAlbum = self.publishModel.repoImageAlbumInfo.imageAlbumData.imageAlbumItems[index];
    [self.stickerService recoveryStickersForContainer:containerView imageModel:oneAlbum.stickerInfo];
    if (index == [self.editService imageAlbumMixed].currentImageEditorIndex) {
        [self updateCurrentStickerContainerWithImageIndex:index];
    }
    oneAlbum.stickerInfo.mediaActualSize = originalImageLayerSize;
    
    ACCStickerLimitEdgeView __block *limitView = nil;
    [containerView.plugins enumerateObjectsUsingBlock:^(__kindof id<ACCStickerContainerPluginProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:ACCStickerLimitEdgeView.class]) {
            limitView = obj;
            *stop = YES;
        }
    }];
    limitView.contentSize = imageLayerSize;
}

- (void)onImageEditorPreviewModeChangedAtContentView:(UIView *)contentView
                                       isPreviewMode:(BOOL)isPreviewMode
{
    ACCStickerContainerView *stickerContainer = [contentView viewWithTag:ACCImageAlbumEditStickerComponentContainerTag];
    [stickerContainer.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (isPreviewMode) {
            BOOL hidden = [self.stickerService shouldDismissInPreviewMode:[obj config].typeId];
            obj.hidden = hidden;
        } else {
            obj.hidden = NO;
        }
    }];
}

- (void)updateCurrentStickerContainerWithImageIndex:(NSInteger)imageIndex
{
    UIView *contentView = [self.editService.imageAlbumMixed currentImageEditorContentView];
    if (contentView) {
        ACCStickerContainerView *stickerContainer = [contentView viewWithTag:ACCImageAlbumEditStickerComponentContainerTag];
        [self setCurrentRootView:contentView
                stickerContainer:stickerContainer
           stickerContainerIndex:imageIndex];
    }
}

- (ACCStickerContainerView *)createSimStickerContainer
{
    ACCVideoEditStickerContainerConfig *config = [[ACCVideoEditStickerContainerConfig alloc] init];
    config.editStickerService = self.editService.sticker;
    config.stickerHierarchyComparator = ^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        if ([obj1 integerValue]< [obj2 integerValue]) {
            return NSOrderedAscending;
        } else if ([obj1 integerValue] > [obj2 integerValue]){
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
    config.ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    
    CGRect playerFrame = CGRectMake(0, 0,
                                    self.editService.mediaContainerView.originalPlayerFrame.size.width,
                                    self.editService.mediaContainerView.originalPlayerFrame.size.height);
    
    ACCStickerContainerView *containerView = [[ACCStickerContainerView alloc] initWithFrame:[UIScreen mainScreen].bounds config:config];
    containerView.delegate = self;
    containerView.hierarchy = [self hierarchyLevel];
    [containerView configWithPlayerFrame:playerFrame allowMask:YES];
    
    return containerView;
}

#pragma mark - Getter & Setter

- (ACCImageAlbumStickerServiceImpl *)stickerService
{
    if (!_stickerService) {
        _stickerService = [[ACCImageAlbumStickerServiceImpl alloc] init];
        @weakify(self);
        _stickerService.stickerContainerLoader = ^ACCStickerContainerView * _Nonnull{
            @strongify(self);
            return self.containerView;
        };
    }
    return _stickerService;
}

@end
