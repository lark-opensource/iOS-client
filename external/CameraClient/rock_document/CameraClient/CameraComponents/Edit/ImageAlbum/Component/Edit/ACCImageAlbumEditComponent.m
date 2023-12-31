//
//  ACCImageAlbumEditComponent.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/11.
//

#import "ACCImageAlbumEditComponent.h"
#import "ACCImageAlbumEditViewModel.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCImageAlbumEditImageInputInfo.h"
#import "ACCImageAlbumEditorGeometry.h"
#import "ACCConfigKeyDefines.h"
#import "ACCEditMusicServiceProtocol.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCImageAlbumSlideGuideView.h"
#import "ACCVideoEditTipsService.h"
#import "ACCVideoEditFlowControlService.h"

#import <CreativeKit/ACCEditViewContainer.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "AWEEditStickerBubbleManager.h"
#import "ACCStudioGlobalConfig.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCImageAlbumAssetsExportManagerProtocol.h"

static NSString *const kACCImageAlbumShowImageScrollGuideKey = @"kACCImageAlbumShowImageScrollGuideKey";

@interface ACCImageAlbumEditComponent() <ACCEditSessionLifeCircleEvent, ACCEditImageAlbumMixedMessageProtocolD, ACCVideoEditFlowControlSubscriber>

@property (nonatomic, strong) ACCImageAlbumEditViewModel *viewModel;
@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, assign) BOOL p_isViewAppear;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsService;

@property (nonatomic, strong) UIImageView *firstPlaceholderImageView;

// 避免reset等操作触发的首次index回调埋点，只有用户手动滑动的才打
@property (nonatomic, assign) NSInteger lastTrackedImageAlbumIndex;

@property (nonatomic, assign) BOOL lastHandlerBubbleVisibleFlag;

@end

@implementation ACCImageAlbumEditComponent
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, tipsService, ACCVideoEditTipsService)

#pragma mark - life cycle
- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
    [self.flowService addSubscriber:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCImageAlbumEditServiceProtocol),
                                   self.viewModel);
}

- (void)componentDidMount
{
    if (![self repository].repoImageAlbumInfo.isImageAlbumEdit) {
        NSAssert(NO, @"should not add image edit component for video edit mode");
        return;
    }
    
    // 图集模式下 图片滑动是有交互的，需要隐藏上层的view遮挡，并且贴纸手势是另外一套实现
    self.viewContainer.gestureView.hidden = YES;
    
    if (ACCConfigBool(kConfigBool_enable_image_album_story)) {
        
        NSTimeInterval autoPlayInterval = ACCConfigDouble(kConfigDouble_image_album_story_auto_play_interval);
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) setAutoPlayInterval:autoPlayInterval];
        if (autoPlayInterval > 0.1) {
            ACCImageAlbumMixedD(self.editService.imageAlbumMixed).enableAutoPlay = YES;
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) setPageControlStyle:ACCImageAlbumEditorPageControlStyleProgress];
        } else {
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) setPageControlStyle:ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol];
        }
        /// 预防view还没appare被其他模块触发auto play
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"viewAppear"];
    } else {
        // 图集模式，支持长条指示器
        NSDictionary *dict = ACCConfigDict(kConfigDict_image_works_experience_optimization);
        NSInteger indicatorStyle = [dict acc_integerValueForKey:kConfigInt_image_indicator_style defaultValue:0];
        if (indicatorStyle == 2) {
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) setPageControlStyle:ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol];
        }
    }
    
    [self setupFirstPlaceholderImageViewIfNeed];
    
    if (self.editService.mediaContainerView.superview) {
        // 图集模式下不应该由其他业务去操作mediaContainerView
        AWELogToolInfo(AWELogToolTagEdit, @"ACCImageAlbumEditComponent : remove mediaContainerView from super view");
        [self.editService.mediaContainerView removeFromSuperview];
    }
    AWELogToolInfo(AWELogToolTagEdit, @"ACCImageAlbumEditComponent : add mediaContainerView to mediaView");
    [self.viewContainer.mediaView addSubview:self.editService.mediaContainerView];

    [self updateMusic];
    [self bindViewModel];
    
}

- (void)componentWillAppear
{
    // 下一个runloop去操作，避免有些component依赖回调没有监听到
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.editService.mediaContainerView resetView];
        [self.editService.imageAlbumMixed setImagePlayerIsPreviewMode:NO];
        [self.editService.imageAlbumMixed resetWithContainerView:self.editService.mediaContainerView];
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"viewAppear"];
        // lite 3 变 2 的编辑页底部需要定制抬高30:
        CGFloat bottomOffset = [ACCStudioGlobalConfig() supportEditWithPublish] ? 30 : 0;
        [self.editService.imageAlbumMixed setPlayerBottomOffset:bottomOffset];
    });
    
    self.p_isViewAppear = YES;
    [self.editService.imageAlbumMixed replayMusic];
}

- (void)componentWillDisappear
{
    self.p_isViewAppear = NO;
    [self.editService.imageAlbumMixed pauseMusic];
    [self.editService.imageAlbumMixed setImagePlayerIsPreviewMode:YES];
    [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"viewAppear"];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)bindViewModel
{
    @weakify(self);
    [[[self musicService].didDeselectMusicSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSAssert(ACCConfigBool(kConfigBool_image_mode_support_delete_music), @"bad case, check, should not deselect music on image edit mode");
        [self updateMusic];
        [ACCImageAlbumAssetsExportManager() clearLastSelectedMusicCache];
    }];
    
    [[[self musicService].didAddMusicSignal deliverOnMainThread] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self updateMusic];
        // 缓存，以供下次直接使用
        [ACCImageAlbumAssetsExportManager() markUserDidSelectMusicWhenEditWithMusic:self.repository.repoMusic.music];
    }];
    
    [self.tipsService.showImageAlbumSlideGuideSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showImageScrollGuideIfNeed];
    }];
   
    [[[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSNotification * _Nullable x) {
        @strongify(self);
        if (self.p_isViewAppear) {
            [self.editService.imageAlbumMixed continuePlayMusic];
        }
    }];
    
    if (ACCConfigBool(kConfigBool_enable_image_album_story)) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_onEditStickerBubbleVisableDidChangedNotify:) name:ACCEditStickerBubbleVisableDidChangedNotify object:nil];
    }
    
    [self.editService.imageAlbumMixed addSubscriber:self];

}

#pragma mark - event
- (void)setupFirstPlaceholderImageViewIfNeed
{
    UIImage *image = [self repository].repoPublishConfig.firstFrameImage;
    
    /// 如果没有 就用原图先垫底下
    if (!image) {
        NSString *firstImageFile = [[self repository].repoImageAlbumInfo.imageEditOriginalImages.firstObject getAbsoluteFilePath];
        if (!ACC_isEmptyString(firstImageFile) && [[NSFileManager defaultManager] fileExistsAtPath:firstImageFile]) {
            image = [UIImage imageWithContentsOfFile:firstImageFile];
        }
    }
 
    if (!image) {
        return;
    }

    CGRect playerFrame = self.editService.mediaContainerView.originalPlayerFrame;

    self.firstPlaceholderImageView = ({
        
        UIImageView *view = [[UIImageView alloc] initWithFrame:playerFrame];
        view.contentMode = ACCImageEditGetWidthFitImageDisplayContentMode(image.size, playerFrame.size);
        view.clipsToBounds = YES;
        view.image = image;
        view;
    });
    
    [self.viewContainer.mediaView addSubview:self.firstPlaceholderImageView];
}

- (void)updateMusic
{
    [self.editService.imageAlbumMixed replaceMusic:self.repository.repoMusic.music];
}

#pragma mark - ACCEditSessionLifeCircleEvent
- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    @weakify(self);
    /// placeholder图本身就在player下面 所以晚点移除没关系的 防止闪一下
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (self.firstPlaceholderImageView) {
            self.firstPlaceholderImageView.hidden = YES;
            [self.firstPlaceholderImageView removeFromSuperview];
            self.firstPlaceholderImageView = nil; // release unusefulness
        }
    });
}

- (void)p_onEditStickerBubbleVisableDidChangedNotify:(NSNotification *)sender
{
    NSString *bubbleName = [sender.userInfo acc_stringValueForKey:ACCEditStickerBubbleVisableDidChangedNotifyGetNameKey];
    
    if ([bubbleName isEqualToString:ACCStickerEditingBubbleManagerName]) {
        BOOL bubbleVisible = [sender.userInfo acc_boolValueForKey:ACCEditStickerBubbleVisableDidChangedNotifyGetVisableKey defaultValue:NO];
        if (bubbleVisible != self.lastHandlerBubbleVisibleFlag) {
            self.lastHandlerBubbleVisibleFlag = bubbleVisible;
            if (bubbleVisible) {
                [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"bubbleVisible"];
            } else {
                [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"bubbleVisible"];
            }
        }
        
    }
}

#pragma mark - ACCEditImageAlbumMixedMessageProtocolD
- (void)onCurrentImageEditorChanged:(NSInteger)currentIndex isByAutoTimer:(BOOL)isByAutoTimer
{
    // 预览页之类的会共用player，所以只在view是appare的情况下才打
    if (self.p_isViewAppear) {
        [self p_trackImageAlbumIndexChangedWithTargetIndex:currentIndex isByAutoTimer:isByAutoTimer];
    }
}

- (void)onPlayerDraggingStatusChanged:(BOOL)isDragging
{
    if (isDragging &&
        ACCConfigInt(kConfigBool_enable_image_album_story_stop_auto_play_after_drag) &&
        ACCImageAlbumMixedD(self.editService.imageAlbumMixed).isAutoPlaying) {
        // 拖动后不再允许恢复自动播
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"PlayerDragging"];
        ACCImageAlbumMixedD(self.editService.imageAlbumMixed).enableAutoPlay = NO;
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) setPageControlStyle:ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol];
    }
}

#pragma mark - getter
- (ACCImageAlbumEditViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCImageAlbumEditViewModel.class];
        NSAssert(_viewModel, @"should not be nil");
    }
    return _viewModel;
}

#pragma mark - track
- (void)p_trackImageAlbumIndexChangedWithTargetIndex:(NSInteger)targetIndex
                                       isByAutoTimer:(BOOL)isByAutoTimer
{
    if (targetIndex == self.lastTrackedImageAlbumIndex) {
        return;
    }
    
    self.lastTrackedImageAlbumIndex = targetIndex;
    
    NSMutableDictionary *params = self.repository.repoTrack.referExtra ? [self.repository.repoTrack.referExtra mutableCopy] : [NSMutableDictionary dictionary];
    
    [params addEntriesFromDictionary:[self.repository.repoTrack mediaCountInfo] ?: @{}];
    
    params[@"pic_location"] = @(targetIndex + 1);
    params[@"is_auto"] = @(isByAutoTimer);
    
    [ACCTracker() trackEvent:@"camera_multi_photo_slide"
                      params:params];
}

#pragma mark - ACCVideoEditFlowControlSubscriber
- (void)didQuickPublishGuideDismiss:(id<ACCVideoEditFlowControlService>)service
{
    [self showImageScrollGuideIfNeed];
}

#pragma mark - guide
- (void)showImageScrollGuideIfNeed
{
    if (!ACCConfigBool(kConfigBool_image_mvp_enable_slide_left_guide)) {
        return;
    }
    
    if (![self repository].repoImageAlbumInfo.isImageAlbumEdit || [self repository].repoDraft.isBackUp) {
        return;
    }

    if ([ACCCache() boolForKey:kACCImageAlbumShowImageScrollGuideKey]) {
        return;
    }
    
    if ([self.repository.repoImageAlbumInfo imageCount] <= 1) {
        return;
    }
    
    [ACCCache() setBool:YES forKey:kACCImageAlbumShowImageScrollGuideKey];
    [self.viewModel updateIsImageScrollGuideAllowed:YES];
    
    ACCImageAlbumSlideGuideView *slidGuide = [[ACCImageAlbumSlideGuideView alloc] initWithFrame:CGRectZero];
    [self.viewContainer.containerView addSubview:slidGuide];
    
    @weakify(self);
    slidGuide.didDisappearBlock = ^{
        @strongify(self);
        [[self viewModel] sendScrollGuideDidDisappearSignal];
    };
    
    ACCMasMaker(slidGuide, {
        make.edges.equalTo(self.viewContainer.containerView);
    });
    
    NSDictionary *referExtra = [self repository].repoTrack.referExtra;
    [ACCTracker() trackEvent:@"camera_photo_slide_popup_show"
                      params:@{
                          @"shoot_way" : [self repository].repoTrack.referString ?: @"",
                          @"creation_id" : [self repository].repoContext.createId ?: @"",
                          @"content_source" : [self repository].repoTrack.contentSource ?: @"",
                          @"content_type" : referExtra[@"content_type"] ?: @"",
                      }];
}

@end
