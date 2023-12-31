//
//  ACCRecorderStickerServiceComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/16.
//

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

#import "ACCRecorderEvent.h"
#import "ACCRecorderStickerServiceComponent.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCStickerHandler+Private.h"
#import "ACCRecorderStickerContainerConfig.h"
#import "ACCRecorderStickerServiceImpl.h"
#import "AWECameraPreviewContainerView.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCRecordSubmodeViewModel.h"
#import "ACCRecordFlowService.h"
#import "ACCRecorderStickerContainerView.h"
#import "ACCRecorderStickerDefines.h"
#import "ACCRecordLayoutManager.h"
#import "AWERepoStickerModel.h"

#pragma mark - ACCRecorderStickerServiceComponent

/* --- Properties and Variables --- */

@interface ACCRecorderStickerServiceComponent ()
<
ACCRecorderEvent,
ACCCameraLifeCircleEvent,
ACCRecordFlowServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver,
ACCRecordSwitchModeServiceSubscriber,
ACCStickerContainerDelegate
>

@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer; // to add views to the recorder, you need to add all subViews to viewContainer's rootView
@property (nonatomic, weak) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) ACCRecorderStickerServiceImpl *stickerService;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, readonly) ACCRecordSubmodeViewModel *recordSubmodeViewModel;

@end

/* --- Implementation --- */

@implementation ACCRecorderStickerServiceComponent

IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecorderStickerServiceProtocol),
                                   self.stickerService);
}

#pragma mark - ACCCameraLifeCircleEvent Methods

- (void)onCameraFirstFrameDidRender:(id<ACCCameraService>)cameraService
{
    
}

#pragma mark - ACCFeatureComponent Life Cycle Methods

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.recorder addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

- (void)loadComponentView
{
    [self.viewContainer addObserver:self];
}

- (void)componentDidMount
{
    [self.stickerService updateStickerContainer];
    [self p_recoverStickersIfNeeded];
}

- (void)componentWillAppear
{
    [self p_buildHandler];
    [[NSNotificationCenter defaultCenter] postNotificationName:kRecorderStickerContainerViewReady
                                                        object:nil
                                                      userInfo:nil];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseLazy;
}

- (void)componentWillDisappear
{
    // 相册选择，MV等路径
    [self p_addRecorderInteractionStickers];
}

#pragma mark - Private Methods

- (void)p_recoverStickersIfNeeded
{
    if (ACC_isEmptyArray(self.repository.repoSticker.recorderInteractionStickers)) {
        return;
    }
    if (!self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
        return;
    }
    [self.stickerService recoverStickers];
}

/// 更新拍摄页的数据到model中，以便于同步拍摄页的贴纸信息到编辑页
/// 被多处调用的原因是以防特殊路径下数据还未保存就生成了编辑页的publishModel（错过数据同步）
- (void)p_addRecorderInteractionStickers
{
    NSMutableArray<AWEInteractionStickerModel *> *interactionStickers = [NSMutableArray array];
    [self.stickerService addRecorderInteractionStickerInfoToArray:interactionStickers idx:0];
    self.repository.repoSticker.recorderInteractionStickers = [NSArray arrayWithArray:interactionStickers];
    self.repository.repoSticker.recordStickerPlayerFrame = self.stickerService.stickerContainerView.playerRect;
    self.repository.repoSticker.shouldRecoverRecordStickers = YES;
}

- (void)p_buildHandler {
    @weakify(self);
    self.stickerService.compoundHandler.stickerContainerLoader = ^ACCStickerContainerView * _Nonnull{
        @strongify(self);
        return self.stickerContainerView;
    };
}

- (void)p_createStickerContainerViewIfNeeded
{
    if (_stickerContainerView) {
        return;
    }
    /* get frame */
    CGRect playerFrame = self.cameraService.cameraPreviewView.frame;
    CGRect containerFrame = self.viewContainer.rootView.bounds;
    if (playerFrame.size.width < 10 || playerFrame.size.height < 10) {
        return;
    }
    /* get config */
    ACCRecorderStickerContainerConfig *config = [[ACCRecorderStickerContainerConfig alloc] init];
    config.stickerHierarchyComparator = ^NSComparisonResult(id _Nonnull obj1,
                                                            id _Nonnull obj2) {
        if ([obj1 integerValue] < [obj2 integerValue]) {
            return NSOrderedAscending;
        } else if ([obj1 integerValue] > [obj2 integerValue]) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    };
    config.ignoreMaskRadiusForXScreen = [AWEXScreenAdaptManager needAdaptScreen] && ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    /* create a container view */
    ACCStickerContainerView *containerView = [[ACCRecorderStickerContainerView alloc] initWithFrame:containerFrame
                                                                                             config:config];
    CGSize videoSize = playerFrame.size;
    BOOL allowMask = !ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
    CGFloat ratio = videoSize.width / videoSize.height;
    if (!isnan(ratio) && !isinf(ratio)) {
        allowMask |= ratio > (9./16.);
    }
    [containerView configWithPlayerFrame:playerFrame
                               allowMask:allowMask];
    containerView.shouldHandleGesture = YES;
    containerView.delegate = self;
    containerView.clipsToBounds = YES;
    /* assign container view to related objects */
    self.stickerContainerView = containerView;
    self.stickerService.compoundHandler.stickerContainerView = containerView;
    self.stickerService.compoundHandler.uiContainerView = self.viewContainer.interactionView;
    /* add sticker container view to a superview */
    ((ACCRecordLayoutManager *)self.viewContainer.layoutManager).stickerContainerView = containerView;
}

- (BOOL)p_couldHandle
{
    return self.stickerContainerView != nil;
}

#pragma mark - Getters and Setters

- (ACCRecorderStickerServiceImpl *)stickerService {
    if (!_stickerService) {
        _stickerService = [[ACCRecorderStickerServiceImpl alloc] initWithRepository:self.repository];
        @weakify(self);
        _stickerService.getStickerContainerViewBlock = ^ACCStickerContainerView * _Nonnull {
            @strongify(self);
            return self.stickerContainerView;
        };
        _stickerService.getViewContainerBlock = ^id<ACCRecorderViewContainer> _Nonnull {
            @strongify(self);
            return self.viewContainer;
        };
    }
    return _stickerService;
}

- (ACCStickerContainerView *)stickerContainerView
{
    if (!_stickerContainerView) {
        [self p_createStickerContainerViewIfNeeded];
    }
    return _stickerContainerView;
}

- (ACCRecordSubmodeViewModel *)recordSubmodeViewModel
{
    return [self getViewModel:[ACCRecordSubmodeViewModel class]];
}

#pragma mark - ACCStickerContainerDelegate Methods

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer
          gestureStarted:(nonnull UIGestureRecognizer *)gesture
                  onView:(nonnull UIView *)targetView
{
    UIView <ACCStickerProtocol> *stickerView = (UIView <ACCStickerProtocol> *)targetView;
    stickerView.contentView.alpha = 1;
    [self.stickerService toggleForbitHidingStickerContainerView:YES];
    self.stickerService.containerInteracting = YES;
}

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer
            gestureEnded:(nonnull UIGestureRecognizer *)gesture
                  onView:(nonnull UIView *)targetView
{
    UIView <ACCStickerProtocol> *stickerView = (UIView <ACCStickerProtocol> *)targetView;
    stickerView.contentView.alpha = kRecorderShootSameStickerViewAlpha;
    [self.stickerService toggleForbitHidingStickerContainerView:NO];
    self.stickerService.containerInteracting = NO;
}

- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer
                         gesture:(nonnull UIGestureRecognizer *)gesture
{
    return NO;
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver Methods (viewContainer subscription)

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    
}

#pragma mark - ACCRecordFlowServiceSubscriber Methods

- (void)flowServiceStateDidChanged:(ACCRecordFlowState)state
                          preState:(ACCRecordFlowState)preState
{
    if (state == ACCRecordFlowStateStart) {
        [self.stickerService toggleStickerContainerViewHidden:YES];
    } else if (state == ACCRecordFlowStatePause) {
        [self.stickerService toggleStickerContainerViewHidden:NO];
    } else if (state == ACCRecordFlowStateStop) {
        [self.stickerService toggleStickerContainerViewHidden:NO];
    } else if (state == ACCRecordFlowStateFinishExport) {
        // Will enter edit view
        
    }
}

- (void)flowServiceWillEnterNextPageWithMode:(ACCRecordMode *)mode
{
    // 拍摄路径
    [self p_addRecorderInteractionStickers];
}

#pragma mark - ACCRecorderEvent Methods

- (void)onStartExportVideoDataWithData:(ACCEditVideoData *)data
{
    [self p_addRecorderInteractionStickers];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber Methods

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode
                                  oldMode:(ACCRecordMode *)oldMode
{
    // 切换文字模式
    if (mode.modeId == ACCRecordModeText ||
        mode.modeId == ACCRecordModeMV) {
        [self p_addRecorderInteractionStickers];
    }
}

@end
