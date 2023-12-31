//
//  ACCVideoEditStickerComponent.m
//  CameraClient
//
//  Created by liuqing on 2020/6/12.
//

#import "AWERepoStickerModel.h"
#import "AWERepoContextModel.h"
#import "ACCVideoEditStickerComponent.h"
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCStickerGestureComponentProtocol.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCStickerLoggerImpl.h"
#import "ACCConfigKeyDefines.h"
#import "ACCStickerPlayerApplyingImpl.h"
#import "ACCStickerServiceImpl.h"
#import "ACCStickerBizDefines.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import "AWEXScreenAdaptManager.h"
#import "ACCStickerContainerView+CameraClient.h"
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import "ACCPublishServiceProtocol.h"
#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import "ACCStickerHandler+Private.h"
#import <CreationKitInfra/ACCGroupedPredicate.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/ACCRepoEditEffectModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "AWEShareMusicToStoryUtils.h"

@interface ACCVideoEditStickerComponent () <
ACCStickerContainerDelegate,
ACCEditTransitionServiceObserver,
ACCEditSessionLifeCircleEvent,
ACCEditPreviewMessageProtocol
>

@property (nonatomic, weak) id<ACCStickerGestureComponentProtocol> stickerGestureComponent;

@property (nonatomic, strong) ACCStickerContainerView *containerView;

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@property (nonatomic, strong) ACCStickerServiceImpl *stickerService;
@property (nonatomic, assign) BOOL isDraftFirstAppear;
@property (nonatomic, strong) ACCEditStickerBizModule *stickerBizModule;

@end

@implementation ACCVideoEditStickerComponent

IESAutoInject(self.serviceProvider, stickerGestureComponent, ACCStickerGestureComponentProtocol)

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - Life Cycle

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateMutipleServiceBinding(@[@protocol(ACCStickerServiceProtocol), @protocol(ACCEditStickerServiceImplProtocol)], self.stickerService);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    self.stickerService.repository = self.repository;
    self.stickerService.editService = self.editService;
    
    [self.editService.preview addSubscriber:self];
    [[self editService] addSubscriber:self];
}

- (void)componentDidMount
{
    self.stickerBizModule = [[ACCEditStickerBizModule alloc] initWithServiceProvider:self.serviceProvider];

    self.isDraftFirstAppear = YES;
    [self buildHandler];
    [self addObserver];
    [self.transitionService registerObserver:self];
    @weakify(self);
    [self viewContainer].topRightBarItemContainer.clickCallback = ^(AWEEditActionItemView * _Nonnull itemView) {
        @strongify(self);
        [self.stickerService deselectAllSticker];
    };
    [self viewContainer].bottomBarItemContainer.clickCallback = ^(AWEEditActionItemView * _Nonnull itemView) {
        @strongify(self);
        [self.stickerService deselectAllSticker];
    };
    
    if ((self.repository.repoDraft.isDraft ||
         self.repository.repoDraft.isBackUp || [self.stickerService.needRecoverStickers evaluate])) {
        
        BOOL hasBeforeEdgeData = self.repository.repoVideoInfo.video.infoStickerAddEdgeData ? YES : NO;
        BOOL hasAfterEdgeData = hasBeforeEdgeData;
        BOOL hasStickers = NO;
        
        if (!ACC_isEmptyArray(self.repository.repoVideoInfo.video.infoStickers) || !ACC_isEmptyArray(self.repository.repoSticker.interactionStickers)) {
            [self.stickerBizModule recoverStickers];
            hasStickers = YES;
        }
        
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"restore canvas has Stickers:%d, isDraft:%d, isBackUp:%d, hasBeforeEdgeData:%d, hasAfterEdgeData:%d",hasStickers, self.repository.repoDraft.isDraft, self.repository.repoDraft.isBackUp, hasBeforeEdgeData, hasAfterEdgeData);
    }
    
    if (self.repository.repoSticker.shouldRecoverRecordStickers)
    {
        [self.stickerService syncRecordSticker];
    }
    /// @warning 注意时机 必须等上面的恢复结束后再从视频里移除
    if (self.repository.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode ||  [self.repository.repoSmartMovie transformedForSmartMovie]) {
        // resetStickerWhenFromImageAlbumModeSwitch
        [self.stickerService resetStickerInPlayer];
    }
    
}

- (void)componentDidUnmount
{
    [self.transitionService unregisterObserver:self];
}

- (void)componentDidAppear
{
    const BOOL isDraftOrBackUp = self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp;
    if (self.isDraftFirstAppear && isDraftOrBackUp) {
        [self.stickerService resetStickerInPlayer];
        self.isDraftFirstAppear = NO;
    }
}

- (ACCStickerServiceImpl *)stickerService {
    if (!_stickerService) {
        _stickerService = [[ACCStickerServiceImpl alloc] init];
        @weakify(self);
        _stickerService.stickerContainerLoader = ^ACCStickerContainerView * _Nonnull{
            @strongify(self);
            return [self loadStickerContainer];
        };
    }
    return _stickerService;
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime {
    if (!self.editService.preview.shouldObservePlayerTimeActionPerform) {
        return;
    }
    if(self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
        currentTime = [self.repository.repoVideoInfo.video totalVideoDuration] - currentTime;
    }
    if (self.containerView) {
        for (NSArray <ACCStickerViewType> *sticker in self.containerView.allStickerViews) {
            if ([sticker conformsToProtocol:@protocol(ACCPlaybackResponsibleProtocol)]) {
                [(id <ACCPlaybackResponsibleProtocol>)sticker updateWithCurrentPlayerTime:currentTime];
            }
        }
    }
}

#pragma mark - sticker handler

- (void)buildHandler {
    self.stickerService.compoundHandler.uiContainerView = self.viewContainer.rootView;
    ACCStickerPlayerApplyingImpl *playerImpl = [[ACCStickerPlayerApplyingImpl alloc] init];
    playerImpl.editService = self.editService;
    playerImpl.stickerService = self.stickerService;
    playerImpl.repository = self.repository;
    playerImpl.isIMRecord = self.repository.repoContext.isIMRecord;
    self.stickerService.compoundHandler.player = playerImpl;
    ACCStickerLoggerImpl *logger = [ACCStickerLoggerImpl new];
    logger.publishModel = self.repository;
    self.stickerService.compoundHandler.logger = logger;
    @weakify(self);
    self.stickerService.compoundHandler.stickerContainerLoader = ^ACCStickerContainerView * _Nonnull{
        @strongify(self);
        return [self loadStickerContainer];
    };
}

#pragma mark - Public Methods

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Private Methods

- (ACCStickerContainerView *)loadStickerContainer
{
    if (self.containerView) {
        return self.containerView;
    }
    
    [self setupContainerView];
    [self.viewContainer.rootView insertSubview:self.containerView belowSubview:self.viewContainer.containerView];

    self.stickerGestureComponent.stickerGestureController.stickerContainerView = self.containerView;

    return self.containerView;
}

- (void)setupContainerView
{
    if (self.containerView) {
        return;
    }
    
    CGRect playerFrame = self.editService.mediaContainerView.frame;
    CGRect containerFrame = self.viewContainer.rootView.bounds;
    
    // iPad横屏模式下从草稿箱进入视频编辑页containerFrame应为竖屏长宽，实际为横屏长宽，所以长宽交换
    BOOL isLandscape = containerFrame.size.width > containerFrame.size.height;
    if([UIDevice acc_isIPad] && isLandscape) {
        containerFrame = CGRectMake(0, 0, containerFrame.size.height, containerFrame.size.width);
    }
    
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
    [config updateMusicCoverWithMusicModel:self.repository.repoMusic.music];
    if (self.repository.repoContext.isIMRecord) {
        [config removePreviewViewPlugin];
    }
    
    ACCStickerContainerView *containerView = [[ACCStickerContainerView alloc] initWithFrame:containerFrame config:config];
    containerView.delegate = self;
    containerView.hierarchy = AWEStickerHierarchyPOISticker;
    [containerView configWithPlayerFrame:playerFrame allowMask:YES];
    containerView.shouldHandleGesture = NO;
    self.containerView = containerView;
    
    self.stickerService.stickerContainer = containerView;
}

- (void)clearAllEffectsAndStickers
{
    ACCEditVideoData *videoData = self.repository.repoVideoInfo.video;
    BOOL shouldShowToast = NO;
    if (videoData.effect_timeRange.count > 0 ||
        videoData.infoStickers.count > 0 ||
        [self.stickerService.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText].count > 0 ||
        [self.stickerService.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdPOI].count > 0 ||
        [self.stickerService.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdPoll].count > 0) {
        shouldShowToast = YES;
    }
    if (shouldShowToast) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ACCToast() showToast: ACCLocalizedString(@"mv_music_change_success", @"音乐更换成功，编辑效果已经重置") ];
        });
    }
    
    // 音乐动效会修改视频时长，移除所有与时长相关的“特效”，“贴纸”
    // 特效：vesdk里面有区间，业务也有用于显示的特效区间，此处都要删除
    // 信息化贴纸：删除videoData里所有信息化贴纸，同时删除业务上的拖动框视图
    // 文字贴纸：删除文字贴纸的拖动视图
    // 投票贴纸：删除投票贴纸的拖动视图
    
    // 1. 删除所有特效区间 & 所有特效显示特效区间
    [[self editService].effect removeAllEffect];
    [self.repository.repoEditEffect.displayTimeRanges removeAllObjects];

    // 2. 删除所有信息化贴纸 & 所有信息化贴纸视图 （歌词贴纸除外）
    [self.editService.sticker removeAll2DStickers];
    for (IESInfoSticker *infoSticker in self.editService.sticker.infoStickers) {
        if (!infoSticker.isSrtInfoSticker) {
            [self.editService.sticker removeInfoSticker:infoSticker.stickerId];
        }
    }
    
    // 5. 删除已选择的贴纸记录
    [self.repository.repoSticker.infoStickerArray removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey object:nil];

    [self.stickerService removeAllInfoStickers];
    
    // 6. 删除封面
    self.repository.repoPublishConfig.firstFrameImage = nil;
    self.editService.mediaContainerView.coverImageView.image = nil;
    // 7. 重新生成封面
    @weakify(self);
    [self.editService.captureFrame getProcessedPreviewImageAtTime:0 preferredSize:[self p_preferredImageSize] compeletion:^(UIImage * _Nonnull image, NSTimeInterval atTime) {
        @strongify(self);
        self.repository.repoPublishConfig.firstFrameImage = image;
        self.editService.mediaContainerView.coverImageView.image = image;
    }];
}

- (void)addObserver
{
    @weakify(self);
    [self.editService.sticker.stickerRegenerateSignal.deliverOnMainThread
     subscribeNext:^(RACTwoTuple<NSNumber *, NSNumber *>  *_Nullable x) {
        @strongify(self);
        [self.stickerService updateStickerViewWithOriginStickerId:x.first.integerValue
                                                     newStickerId:x.second.integerValue];
    }];
    
    [[[[[NSNotificationCenter defaultCenter]
     rac_addObserverForName:kAWEVideoNewPublishViewControllerWillDismissNotification object:nil]
     takeUntil:self.rac_willDeallocSignal]
     deliverOnMainThread]
     subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        [self.stickerService resetStickerInPlayer];
    }];
}

- (CGSize)p_preferredImageSize
{
    CGSize imageSize = CGSizeMake(540, 960);
    if (self.repository.repoVideoInfo.sizeOfVideo) {
        imageSize = self.repository.repoVideoInfo.sizeOfVideo.CGSizeValue;
        if (imageSize.width > 540.0) {
            CGFloat scale = imageSize.width / 540.0;
            imageSize = CGSizeMake(540.0, imageSize.height / scale);
        }
    }
    return imageSize;
}

#pragma mark - Sticker Container Delegate

- (void)stickerContainer:(ACCStickerContainerView *)board gestureStarted:(nonnull UIGestureRecognizer *)gesture onView:(nonnull UIView *)targetView
{
    self.repository.repoContext.isStickerEdited = YES;
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        [self.stickerGestureComponent startNewStickerPanOperation];
    }
}

- (void)stickerContainer:(ACCStickerContainerView *)board gestureEnded:(nonnull UIGestureRecognizer *)gesture onView:(nonnull UIView *)targetView
{
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        [self.stickerGestureComponent finishNewStickerPanOperation];
    }
}

- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer gesture:(UIGestureRecognizer *)gesture
{
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isTextStickerShortcutEnabled]) {
        [self.stickerService startQuickTextInput];
        return YES;
    }
    return NO;
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    // 开启实验的时候点击编辑页就会触发添加文字贴纸操作，需要提前加载贴纸容器
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) isTextStickerShortcutEnabled]) {
        [self loadStickerContainer];
    }
    
    [ACCCustomFont() prefetchFontEffects];
    
    AWERepoStickerModel *repoStickerModel = self.repository.repoSticker;
    if (repoStickerModel.stickerConfigAssembler != nil) {
        [self.stickerService expressStickers];
        repoStickerModel.stickerConfigAssembler = nil;
    }
    
}

#pragma mark - ACCEditTransitionServiceObserver

- (void)transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService willPresentViewController:(UIViewController *)viewController
{
    [self.stickerService deselectAllSticker];
}

- (void)willEnterPublish
{
    [self.stickerBizModule readyForPublish];
    [self.stickerService finish];
}

@end
