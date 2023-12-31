//
//  ACCEditSmartMovieComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/7/29.
//

#import "ACCEditSmartMovieComponent.h"
#import "ACCBarItem+Adapter.h"
#import "ACCConfigKeyDefines.h"
#import "AWEEditPageProtocol.h"
#import "ACCEditorDraftService.h"
#import "ACCVideoEditTipsService.h"
#import "ACCEditToolBarContainer.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCEditSmartMovieViewModel.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCVideoEditToolBarDefinition.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCEditViewContainer.h>

#import <CameraClient/ACCNLEUtils.h>
#import <CameraClient/AWERepoMusicModel.h>
#import <CameraClient/ACCSmartMovieUtils.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <CameraClient/ACCSmartMovieDefines.h>
#import <CameraClient/ACCEditorDraftService.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import <CameraClient/ACCEditPreviewProtocolD.h>
#import <CameraClient/ACCNLEEditPreviewWrapper.h>
#import <CameraClient/ACCImageAlbumEditInputData.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCEditMusicServiceProtocol.h>
#import <CameraClient/ACCVideoEditFlowControlService.h>
#import <CameraClient/ACCImageAlbumEditTransferProtocol.h>
#import <CameraClient/ACCImageAlbumLandingModeManagerProtocol.h>

#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>

#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>

#import <CameraClient/ACCNLEEditVideoData.h>
#import <CameraClient/ACCEditSmartMovieProtocol.h>
#import <CameraClient/ACCEditVideoDataDowngrading.h>

#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDNetworkUtilities.h>

@interface ACCEditSmartMovieComponent()

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) id<ACCVideoEditTipsService> tipsService;
@property (nonatomic, strong) id<ACCEditSmartMovieProtocol> smartMovieService;
@property (nonatomic, strong) id<ACCVideoEditFlowControlService> flowService;
@property (nonatomic, strong) id<ACCEditMusicServiceProtocol> editMusicService;
@property (nonatomic, strong) id<ACCEditorDraftService> draftService;
@property (nonatomic, strong) ACCEditSmartMovieViewModel *viewModel;
@property (nonatomic, weak) id<ACCSmartMovieManagerProtocol> smManager;
@property (nonatomic, assign) AWEPublishFlowStep flowStep;
@property (nonatomic, assign) BOOL needsReplay;

@end

@implementation ACCEditSmartMovieComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, draftService, ACCEditorDraftService)
IESAutoInject(self.serviceProvider, tipsService, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, flowService, ACCVideoEditFlowControlService)
IESAutoInject(self.serviceProvider, editMusicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, smartMovieService, ACCEditSmartMovieProtocol)

#pragma mark - Life Cycle
- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.flowStep = [self publishModel].repoFlowControl.step;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }

    [self configInfos];
    [self bindViewModel];
}

- (void)componentDidUnmount
{
    self.editService.preview.autoPlayWhenAppBecomeActive = NO;
}

#pragma mark - Config

- (void)configInfos
{
    // 防止数据有误（从草稿恢复的时候用得到）
    BOOL isBackUpFromDraft = ([self publishModel].repoDraft.isDraft || [self publishModel].repoDraft.isBackUp);
    id<ACCEditVideoDataProtocol>videoData = [self publishModel].repoVideoInfo.video;
    if ([self isSmartMovieMode]) {
        [self.smManager setCurrentScene:ACCSmartMovieSceneModeSmartMovie];
        if (isBackUpFromDraft) {
            [self publishModel].repoSmartMovie.videoForSmartMovie = videoData;
        }
    } else if ([self isMVVideoMode]) {
        [self.smManager setCurrentScene:ACCSmartMovieSceneModeMVVideo];
        if (isBackUpFromDraft) {
            [self publishModel].repoSmartMovie.videoForMV = videoData;
        }
    }
}

- (void)loadComponentView
{
    [self.viewContainer addToolBarBarItem:[self smartMovieBarItem]];
 
    // 草稿恢复场景，重新请求音乐列表
    BOOL isBackUpFromDraft = ([self publishModel].repoDraft.isDraft || [self publishModel].repoDraft.isBackUp);
    if (isBackUpFromDraft) {
        [self.smManager refreshMusicListWithAssets:[self publishModel].repoSmartMovie.assetPaths];
    }
}

- (void)bindViewModel
{
    @weakify(self);
    [[[self.smartMovieService.willSwitchMusicSignal deliverOnMainThread] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self onSwitchSmartMovieMusic:x];
    }];
    [[[self.tipsService.showSmartMovieBubbleSignal deliverOnMainThread] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showBubbleTipsIfNeeded];
    }];
    if ([self isSmartMovieMode]) {
        [[[RACObserve(self.smartMovieService.nle, status).distinctUntilChanged deliverOnMainThread] takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            NLEPlayerStatus status = [x integerValue];
            if ((status == NLEPlayerStatusPlaying) && self.smManager.isResignActive) {
                [self.editService.preview pause];
                self.needsReplay = YES;
            }
        }];
        [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil] takeUntil:[self rac_willDeallocSignal]] subscribeNext:^(NSNotification *_Nullable x) {
            @strongify(self);
            if (self.needsReplay) {
                [self.editService.preview play];
                self.needsReplay = NO;
            }
        }];
    }
}

#pragma mark - Action
- (void)onBarItemButtonClicked:(UIButton *)sender
{
    if (!BTDNetworkConnected()) {
        [ACCToast() showError:@"网络不给力，请稍后重试"];
        return;
    }
    
    ACCSmartMovieSceneMode toMode = sender.selected ? ACCSmartMovieSceneModeSmartMovie : ACCSmartMovieSceneModeMVVideo;
    
    // 如果数据一致则不需要切换
    if ([self canIgnoreSwitchEvent:toMode]) {
        // 数据类型一致，说明按钮的状态有问题，重新校准一次
        [self reverseBarItemState];
        return;
    }
    
    [self transferSceneModeTo:toMode withMusic:nil];
}

- (void)transferSceneModeTo:(ACCSmartMovieSceneMode)toMode withMusic:(id<ACCMusicModelProtocol> _Nullable)music
{
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    UIView *snapshot = [self screenshot];
    [window addSubview:snapshot];
    
    NSString *toast = (toMode == ACCSmartMovieSceneModeMVVideo) ? @"默认效果加载中" : @"智能转场效果加载中";
    BOOL isSwitchMusic = music.musicID ? YES : NO;
    @weakify(self);
    if (toMode == ACCSmartMovieSceneModeMVVideo) {
        [ACCLoading() showWindowLoadingWithTitle:toast animated:YES];
    } else {
        [[ACCLoading() showWindowLoadingWithTitle:toast animated:YES] showCloseBtn:YES closeBlock:^{
            @strongify(self);
            [self.smManager cancelExport];
        }];
    }
    
    @weakify(snapshot);
    void(^deferBlock)(BOOL, NSString *) = ^(BOOL succeed, NSString *errorLogMsg) {
        if (!NSThread.isMainThread) {
            NSAssert(NO, @"deferBlock must work on the main thread");
            AWELogToolError(AWELogToolTagEdit, @"ACCEditSmartMovieComponent : thread error:%@, succeed:%@ errorLogMsg:%@, toMode:%@", NSThread.currentThread, @(succeed), errorLogMsg, @(toMode));
        }
        acc_dispatch_main_async_safe(^{
            @strongify(self, snapshot);
            [self recoveryWhenUserCancelExport];
            [snapshot removeFromSuperview];
            if ([errorLogMsg isEqualToString:ACCSmartMovieExportCancelByUserKey]) {
                AWELogToolInfo(AWELogToolTagMV, @"SmartMovie: export canceled by user, toMode:%@", @(toMode));
            }
            [ACCLoading() dismissWindowLoadingWithAnimated:YES];
            if (!succeed && !isSwitchMusic) {
                [self reverseBarItemState];
                [ACCToast() show:@"网络不给力，请稍后重试"];
            }
        });
    };
    
    UIViewController<AWEEditPageProtocol> *currentEditPage = (UIViewController<AWEEditPageProtocol> *)self.controller.root;
    if (!currentEditPage || ![currentEditPage conformsToProtocol:@protocol(AWEEditPageProtocol)]) {
        /// @warning 未来如果触发此断言说明编辑页的层级结构变了，需要图片编辑这里对应修改
        NSAssert(NO, @"!!! fatal case !!! please check");
        ACCBLOCK_INVOKE(deferBlock, NO, @"vc hierarchy error, current root page is not AWEEditPage");
        return;
    }
    
    ACCEditViewControllerInputData *inputData = [self inputData];
    if (!inputData) {
        NSAssert(NO, @"bad case, check");
        ACCBLOCK_INVOKE(deferBlock, NO, @"no image album edit input data");
        return;
    }
    
    AWEVideoPublishViewModel *currentPublishModel = [self publishModel];
    
    ACCImageAlbumEditInputData *imageAlbumEditInputData = inputData.imageAlbumEditInputData;
    __block AWEVideoPublishViewModel *transPublishModel = nil;
    id<ACCEditVideoDataProtocol> transVideoData = [self transferVideoDataTo:toMode];
    void(^transferHandler)(void) = ^(void) {
        @strongify(self);
        
        UINavigationController *navigationController = currentEditPage.navigationController;
        NSMutableArray <UIViewController *> *viewControllers = [NSMutableArray arrayWithArray:navigationController.viewControllers];
        
        if (![viewControllers containsObject:currentEditPage]) {
            /// 未来如果触发此断言说明编辑页的层级结构变了，需要图片编辑这里对应修改
            NSAssert(NO, @"!!! fatal case !!! check");
            ACCBLOCK_INVOKE(deferBlock, NO, @"navigation hierarchy error, viewControllers did not contain current edit vc");
            return;
        }
        
        // 更新context，防止递归引用
        transPublishModel.repoContext.sourceModel = nil;
        
        // 在转场之前，把当前编辑的publishModel缓存起来，下次切换在恢复
        // 因为传入编辑页已经进行过copy 所以会导致不同源 如果不重新赋值，编辑效果会丢失
        id<ACCImageAlbumLandingModeManagerProtocol> landingModeManager = IESAutoInline(ACCBaseServiceProvider(), ACCImageAlbumLandingModeManagerProtocol);
        
        if (toMode == ACCSmartMovieSceneModeSmartMovie) {
            transPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeSmartMovie;
            [landingModeManager.class markUsedSmartMovieMode];
        } else {
            transPublishModel.repoSmartMovie.videoMode = ACCSmartMovieSceneModeMVVideo;
            [landingModeManager.class markUsedPhotoVideoMode];
        }
        
        imageAlbumEditInputData.videoModePublishModel = transPublishModel;
        
        // 更新数据，为了能保持草稿为当前编辑
        transPublishModel.repoFlowControl.step = self.flowStep;
        
        [viewControllers removeObject:currentEditPage];
        navigationController.viewControllers = [viewControllers copy];
        
        // @brief: 参考“变图集/变视频”模式。
        // 热切不支持（直接替换NLEModel生成的videoData方案，由于VE底层对于单轨和多轨的播放器不同切不可逆，因此不支持）
       
        // 延迟切换 避免两个VC同时存在内存峰值过高
        // 理论上下个runloop即可，但是有一些中间纹理数据之类的清理可能并不是立即结束,保守起见加了点延迟
        // 另一种方案是考虑缓存不同编辑模式下的VC，但是内存占用会占用100-200M，性能上考虑采用新建VC走草稿恢复模式
        
        // Create a temporary cancelBlock and assign it to the new edit page after the old edit page deallocated
        AWEEditAndPublishCancelBlock tmpCancelBlock = nil;
        if (currentEditPage && [currentEditPage conformsToProtocol:@protocol(AWEEditPageProtocol)]) {
            tmpCancelBlock = [(UIViewController<AWEEditPageProtocol> *)(currentEditPage) inputData].cancelBlock;
        }
        
        @weakify(navigationController);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            /// @warning 这block里面不要再用self，已经释放
            
            // 理论上不需要，保险起见 weak了下navi
            @strongify(navigationController);
            
            if (!navigationController) {
                NSAssert(NO, @"!!! fatal case !!! why? check");
                ACCBLOCK_INVOKE(deferBlock, NO, @"navigation vc released");
            }
            
            UIViewController<AWEEditPageProtocol> *willTransforToEditPage = [ACCImageAlbumEditTransfer() videoEditorWithModel:transPublishModel];
            
            // videoEditorWithModel里面copy了,所以指向一下 防止不同源产生问题
            // 虽然切换后也会重新指向一次，但是提前指向一次防止以后再中间过程用到留坑
            transPublishModel = willTransforToEditPage.inputData.publishModel ?: transPublishModel;

            imageAlbumEditInputData.videoModePublishModel = transPublishModel;
            
            willTransforToEditPage.inputData.imageAlbumEditInputData = [imageAlbumEditInputData copy];
            if (tmpCancelBlock) {
                willTransforToEditPage.inputData.cancelBlock = tmpCancelBlock;
            }
            
            // 重新取一下 毕竟延迟了防止vc堆栈有问题
            NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:navigationController.viewControllers];
            [viewControllers btd_addObject:willTransforToEditPage];
            navigationController.viewControllers = [viewControllers copy];
            
            ACCBLOCK_INVOKE(deferBlock, YES, nil);
        });
    };
    
    void(^hotSwitchHandler)(void) = ^(void) {
        @strongify(self);
        if (![self.editService.preview isKindOfClass:ACCNLEEditPreviewWrapper.class]) {
            [self.viewModel recoveryRepository:currentPublishModel];
            NSAssert(NO, @"预览页必须是ACCNLEEditPreviewWrapper才支持热切！");
            return;
        }
        [self refreshPlayerContentsCompletion:deferBlock];
    };
    
    if (toMode == ACCSmartMovieSceneModeSmartMovie) {
       
        if (isSwitchMusic) {
            [self switchMusic:music
                forRepository:currentPublishModel
                     transfer:hotSwitchHandler
                        defer:deferBlock];
            return;
        }
        
        // 设置场景
        [self.smManager setCurrentScene:ACCSmartMovieSceneModeSmartMovie];
        
        // 为了统一音乐列表，记录来源场景
        self.smManager.previousScene = ACCSmartMovieSceneModeMVVideo;

        // 贴纸打包和保存当前NLE编辑数据
        [self.flowService notifyWillSwitchSmartMovieEditMode];
        [self synchronousNleToRepository:currentPublishModel];
        
        // 缓存当前的数据
        currentPublishModel.repoSmartMovie.videoForMV = currentPublishModel.repoVideoInfo.video;
        transPublishModel = [currentPublishModel copy];
        
        // 首次MV视频切智照需要先合成智照视频
        if (!transVideoData || !transPublishModel.repoMusic.music || (![transPublishModel.repoSmartMovie.musicForSmartMovie.musicID isEqualToString:transPublishModel.repoMusic.music.musicID])) {
            // 用户手动切换音乐的话，就使用最后选择的
            NSString *exportMusicID = transPublishModel.repoMusic.music.musicID;
            [self reExportSmartMovieWithRepository:transPublishModel
                                           musicID:exportMusicID
                                          transfer:transferHandler
                                             defer:deferBlock];
            if (![transPublishModel.repoSmartMovie.musicForSmartMovie.musicID isEqualToString:transPublishModel.repoMusic.music.musicID]) {
                if (transPublishModel.repoMusic.music) {
                    transPublishModel.repoSmartMovie.musicForSmartMovie = transPublishModel.repoMusic.music;
                } else {
                    transPublishModel.repoMusic.music = transPublishModel.repoSmartMovie.musicForSmartMovie;
                }
            }
        } else {
            [self updateRepository:transPublishModel
                         videoData:transVideoData
                       constructor:^BOOL (AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils syncMVTracks:trans];
                return NO;
            }];
            ACCBLOCK_INVOKE(transferHandler);
        }
        
    } else if (toMode == ACCSmartMovieSceneModeMVVideo) {
        
        // 设置场景
        [self.smManager setCurrentScene:ACCSmartMovieSceneModeMVVideo];
        
        // 为了统一音乐列表，记录来源场景
        self.smManager.previousScene = ACCSmartMovieSceneModeSmartMovie;
        
        // 贴纸打包和保存当前NLE编辑数据
        [self.flowService notifyWillSwitchSmartMovieEditMode];
        [self synchronousNleToRepository:currentPublishModel];
        
        // 缓存当前的数据
        currentPublishModel.repoSmartMovie.videoForSmartMovie = currentPublishModel.repoVideoInfo.video;
        transPublishModel = [currentPublishModel copy];

        // 首次智照切MV视频需要先合成MV视频
        if (!transVideoData || !transPublishModel.repoMusic.music || (![transPublishModel.repoMusic.music.musicID isEqualToString:transPublishModel.repoSmartMovie.musicForMV.musicID])) {
            [self reExportMVWithRepository:transPublishModel
                                   current:currentPublishModel
                                  transfer:transferHandler
                                     defer:deferBlock];
        } else {
            [self updateRepository:transPublishModel
                         videoData:transVideoData
                       constructor:^BOOL (AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils syncSmartMovieTracks:trans];
                return NO;
            }];
            ACCBLOCK_INVOKE(transferHandler);
        }
    }
    
    // track event
    [self p_trackSmartMovieButtonClicked:toMode publishModel:currentPublishModel];
}

#pragma mark - Transfer Methods
- (void)switchMusic:(id<ACCMusicModelProtocol>)music
      forRepository:(AWEVideoPublishViewModel *)repository
           transfer:(void(^)(void))transferBlock
              defer:(void(^)(BOOL succeed, NSString *errorMsg))deferBlock
{
    repository.repoSmartMovie.videoForSmartMovie = repository.repoVideoInfo.video;
    repository.repoMusic.music = music;
    // 设置bgmAsset，是因为不设置的话换音乐音量会被置为0
    repository.repoMusic.bgmAsset = [AVAsset assetWithURL:music.loaclAssetUrl];
    @weakify(self);
    [self.viewModel refreshRepository:[repository copy]
                              musicID:music.musicID
                              succeed:^(AWEVideoPublishViewModel * _Nonnull result,
                                        BOOL isCanceled) {
        @strongify(self);
        if (isCanceled) {
            [self.viewModel recoveryRepository:repository];
            [self.smartMovieService triggerSignalForRecovery];
            // 用户取消不算错误
            ACCBLOCK_INVOKE(deferBlock, YES, ACCSmartMovieExportCancelByUserKey);
        } else {
            id<ACCEditVideoDataProtocol> videoData = result.repoVideoInfo.video;
            [self updateRepository:repository
                         videoData:videoData
                       constructor:^BOOL (AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils mergeModeTracks:ACCSmartMovieSceneModeSmartMovie to:trans];
                return YES;
            }];
            repository.repoSmartMovie.videoForSmartMovie = videoData;
            ACCBLOCK_INVOKE(transferBlock);
        }
        self.smManager.sceneDataMarker.smartMovieDataExist = YES;
    } failed:^{
        ACCBLOCK_INVOKE(deferBlock, NO, @"switch Smart Movie music faild");
    }];
}

- (void)reExportMVWithRepository:(AWEVideoPublishViewModel *)repository
                         current:(AWEVideoPublishViewModel *)currentPublishModel
                        transfer:(void(^)(void))transferBlock
                           defer:(void(^)(BOOL succeed, NSString *errorMsg))deferBlock
{
    @weakify(self)
    [self.viewModel exportDataForMode:ACCSmartMovieSceneModeMVVideo
                           repository:repository
                              musicID:nil
                              succeed:^(AWEVideoPublishViewModel * _Nonnull result,
                                        BOOL isCanceled) {
        @strongify(self)
        if (isCanceled) {
            self.smManager.sceneDataMarker.mvDataExist = NO;
            ACCBLOCK_INVOKE(deferBlock, YES, ACCSmartMovieExportCancelByUserKey);  // 用户取消不算错误
        } else {
            id<ACCEditVideoDataProtocol> videoData = result.repoVideoInfo.video;
            [self updateRepository:repository
                         videoData:videoData
                       constructor:^(AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils syncSmartMovieTracks:trans];
                // 用户曾手动换音乐的话，用最后选择的
                @strongify(self);
                if (currentPublishModel.repoMusic.music &&
                    trans.repoMusic.music.musicID != currentPublishModel.repoMusic.music.musicID) {
                    // 带上现在的音乐去跳转场景
                    [self.smartMovieService useMusic:currentPublishModel.repoMusic.music
                                        ForVideoData:videoData];
                    trans.repoMusic.music = currentPublishModel.repoMusic.music;
                    trans.repoMusic.bgmAsset = [AVAsset assetWithURL:currentPublishModel.repoMusic.music.loaclAssetUrl];
                } else if (!currentPublishModel.repoMusic.music) {
                    // 取消了配乐，到mv场景也是无声
                    [self.smartMovieService dismissMusicForVideoData:videoData];
                    trans.repoMusic.music = nil;
                    trans.repoMusic.bgmAsset = nil;
                }
                return NO;
            }];
            self.smManager.sceneDataMarker.mvDataExist = YES;
            ACCBLOCK_INVOKE(transferBlock);
        }
    } failed:^{
        ACCBLOCK_INVOKE(deferBlock, NO, @"export MV Video faild");
    }];
}

- (void)reExportSmartMovieWithRepository:(AWEVideoPublishViewModel *)repository
                                 musicID:(NSString *_Nullable)musicID
                                transfer:(void(^)(void))transferBlock
                                   defer:(void(^)(BOOL succeed, NSString *errorMsg))deferBlock
{
    @weakify(self)
    [self.viewModel exportDataForMode:ACCSmartMovieSceneModeSmartMovie
                           repository:repository
                              musicID:musicID
                              succeed:^(AWEVideoPublishViewModel * _Nonnull result,
                                        BOOL isCanceled) {
        @strongify(self);
        if (isCanceled) {
            [self reverseBarItemState];
            ACCBLOCK_INVOKE(deferBlock, YES, ACCSmartMovieExportCancelByUserKey);  // 用户取消不算错误
        } else {
            id<ACCEditVideoDataProtocol> videoData = result.repoVideoInfo.video;
            [self updateRepository:repository
                         videoData:videoData
                       constructor:^BOOL (AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils syncMVTracks:trans];
                return NO;
            }];
            self.smManager.sceneDataMarker.smartMovieDataExist = YES;
            ACCBLOCK_INVOKE(transferBlock);
        }
    } failed:^{
        ACCBLOCK_INVOKE(deferBlock, NO, @"export Smart Movie Video faild");
    }];
}

#pragma mark - Signal Action

- (void)onSwitchSmartMovieMusic:(id<ACCEditSmartMovieMusicTupleProtocol>)tuple
{
    if (!tuple || ![tuple conformsToProtocol:@protocol(ACCEditSmartMovieMusicTupleProtocol)]) {
        return;
    }
    if (!tuple.to || ![tuple.to conformsToProtocol:@protocol(ACCMusicModelProtocol)]) {
        [self publishModel].repoMusic.music = tuple.from;
        return;
    }
    
    if (tuple.to.isLocalScannedMedia && tuple.to.loaclAssetUrl) {
        // 切换本地音频，效果不变，仅做音频替换
        [self.viewModel backupMusic:tuple.from];
        [self.smartMovieService useLocalMusic:tuple.to
                       withTotalVideoDuration:[self publishModel].repoVideoInfo.video.totalVideoDuration];
        [self publishModel].repoMusic.music = tuple.to;
        [self publishModel].repoMusic.bgmAsset = [AVAsset assetWithURL:tuple.to.loaclAssetUrl];
        return;
    }
    
    if (ACC_isEmptyString(tuple.to.musicID) || !tuple.to.loaclAssetUrl) {
        [self publishModel].repoMusic.music = tuple.from;
        return;
    }

    BOOL isSupportHotSwitch = [self.editService.preview isKindOfClass:ACCNLEEditPreviewWrapper.class];
    if ([self isSmartMovieMode] && isSupportHotSwitch) {
        [self.viewModel backupMusic:tuple.from];
        [self transferSceneModeTo:ACCSmartMovieSceneModeSmartMovie withMusic:tuple.to];
    }
}

#pragma mark - Private Methods

- (void)reverseBarItemState
{
    UIButton *itemView = [self smartMovieBarItemButton];
    [self resetBarItem:itemView toState:ACCSmartMovieBarItemStateReverse];
}

- (UIButton *)resetBarItem:(UIView *)itemView toState:(ACCSmartMovieBarItemState)state
{
    UIButton *itemButton = nil;
    if ([itemView isKindOfClass:[UIButton class]]) {
        itemButton = (UIButton *)itemView;
    } else if ([itemView respondsToSelector:@selector(button)]) {
        itemButton = [itemView performSelector:@selector(button)];
    } else {
        // 这个断言用于校验，以方便后期重构ACCBarItem的barItemViewConfigBlock时，及时发现不符合预期的变更
        NSAssert(NO, @"@selector(button) is removed from the itemView, please confirm if you need to do this");
    }
    switch (state) {
        case ACCSmartMovieBarItemStateOn: {
            itemButton.selected = YES;
            break;
        }
        case ACCSmartMovieBarItemStateOff: {
            itemButton.selected = NO;
            break;
        }
        case ACCSmartMovieBarItemStateReverse: {
            itemButton.selected = !itemButton.selected;
            break;
        }
        default:
            break;
    }
    
    // accessibility control
    if (itemButton.isSelected) {
        itemButton.accessibilityLabel = @"智能转场开启";
    } else {
        itemButton.accessibilityLabel = @"智能转场关闭";
    }
    
    return itemButton;
}

- (void)showBubbleTipsIfNeeded
{
    AWEVideoPublishViewModel *publishModel = [self publishModel];
    if (![ACCSmartMovieABConfig defaultMV]) {
        return;
    }
    
    if ([publishModel.repoSmartMovie isSmartMovieMode]) {
        return;
    }
  
    if (publishModel.repoDraft.isDraft || publishModel.repoDraft.isBackUp) {
        return;
    }

    if (!acc_isOpenSmartMovieCapabilities(publishModel)) {
        return;
    }

    if ([ACCCache() boolForKey:kACCSmartMovieBubbleTipsHasShownKey]) {
        return;
    }
    
    [ACCCache() setBool:YES forKey:kACCSmartMovieBubbleTipsHasShownKey];
    [self.smartMovieService updateSmartMovieBubbleAllowed:YES];
    
    NSString *content = @"试试新的图片智能转场效果";
    let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarSmartMovieContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
    [self.tipsService showFunctionBubbleWithContent:content
                                            forView:[self smartMovieBarItemButton]
                                      containerView:self.viewContainer.containerView
                                          mediaView:self.editService.mediaContainerView
                                   anchorAdjustment:CGPointZero
                                        inDirection:direction
                                       functionType:AWEStudioEditFunctionSmartMovie];
}

- (UIView *)screenshot
{
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    UIImage *snapshotImage = [window acc_snapshotImageAfterScreenUpdates:NO];
    UIImageView *snapshot = [[UIImageView alloc] initWithFrame:window.bounds];
    snapshot.image = snapshotImage;
    return snapshot;
}

- (BOOL)canIgnoreSwitchEvent:(ACCSmartMovieSceneMode)toMode
{
    if (toMode == ACCSmartMovieSceneModeSmartMovie) {
        return [self isSmartMovieMode];
    }
    if (toMode == ACCSmartMovieSceneModeMVVideo) {
        return [[self publishModel].repoSmartMovie isMVMode];
    }
    return YES;
}

- (BOOL)isMVVideoMode
{
    return [[self publishModel].repoSmartMovie isMVMode];
}

- (BOOL)isSmartMovieMode
{
    return [[self publishModel].repoSmartMovie isSmartMovieMode];
}

- (void)recoveryWhenUserCancelExport
{
    [self.smManager prepareToProcessSmartMovie];
}

- (void)refreshDraftForSmartMovie
{
    if ([self isSmartMovieMode]) {
        [self publishModel].repoFlowControl.step = self.flowStep;
        [[self draftService] saveDraftIfNecessary];
    }
}

- (void)synchronousNleToRepository:(nonnull AWEVideoPublishViewModel *)repository
{
    NLEEditor_OC *nleEditor = self.smartMovieService.nle.editor;
    if (nleEditor && repository) {
        [ACCNLEUtils syncNLEEditor:nleEditor repository:repository];
    }
}

- (void)refreshPlayerContentsCompletion:(void(^)(BOOL succeed,NSString *errorMsg))completion
{
    ACCNLEEditPreviewWrapper *preview = (ACCNLEEditPreviewWrapper *)self.editService.preview;
    UIViewController<AWEEditPageProtocol> *currentEditPage = (UIViewController<AWEEditPageProtocol> *)self.controller.root;
    
    @weakify(self, currentEditPage)
    // 重新渲染
    
    ACCEditVideoData *videoData = [self publishModel].repoVideoInfo.video;
    [preview updateVideoData:videoData
                  updateType:VEVideoDataUpdateAll
               completeBlock:^(NSError *error) {
        @strongify(self, currentEditPage);
        if (!error) {
            
            // 更新缓存数据
            [self publishModel].repoSmartMovie.videoForSmartMovie = videoData;
            ACCImageAlbumEditInputData *imageAlbumEditInputData = [self inputData].imageAlbumEditInputData;
            imageAlbumEditInputData.videoModePublishModel = [[self publishModel] copy];
            currentEditPage.inputData.imageAlbumEditInputData = [imageAlbumEditInputData copy];
            [self.smartMovieService triggerSignalForDidSwitchMusic];
            [self.editService.preview play];
            [self refreshDraftForSmartMovie];
            ACCBLOCK_INVOKE(completion, YES, nil);
        } else {
            // 回滚数据
            [self updateRepository:[self publishModel]
                         videoData:[self publishModel].repoSmartMovie.videoForSmartMovie
                       constructor:^BOOL(AWEVideoPublishViewModel *trans) {
                [ACCSmartMovieUtils syncSmartMovieTracks:trans];
                return NO;
            }];
            // 数据报错
            ACCBLOCK_INVOKE(completion, NO, error.localizedDescription);
        }
    }];
}

- (void)updateRepository:(AWEVideoPublishViewModel *)repository
               videoData:(id<ACCEditVideoDataProtocol>)videoData
             constructor:(BOOL(^)(AWEVideoPublishViewModel *trans))constructor
{
    if (videoData && [videoData isKindOfClass:ACCNLEEditVideoData.class]) {
        ACCNLEEditVideoData *nleVideoData = (ACCNLEEditVideoData *)videoData;
        [repository.repoVideoInfo updateVideoData:nleVideoData];
        if (repository.repoMusic.music) {
            [self p_updateMusicInfoOfPublishModel:repository videoData:nleVideoData];
        }
        if (ACCBLOCK_INVOKE(constructor, repository)) {
            NLEEditor_OC *editor = self.smartMovieService.nle.editor;
            [editor setModel:nleVideoData.nleModel];
            [editor acc_commitAndRender:nil];
        }
    }
}

- (nullable id<ACCEditVideoDataProtocol>)transferVideoDataTo:(ACCSmartMovieSceneMode)toMode
{
    if (toMode == ACCSmartMovieSceneModeMVVideo) {
        return [self publishModel].repoSmartMovie.videoForMV;
    }
    return [self publishModel].repoSmartMovie.videoForSmartMovie;
}

#pragma mark - private

- (void)p_updateMusicInfoOfPublishModel:(AWEVideoPublishViewModel *)publishModel
                              videoData:(ACCNLEEditVideoData *)videoData
{
    if (!publishModel || !videoData) {
        return;
    }
    
    NSString *pathInModel = [publishModel.repoMusic.music.loaclAssetUrl absoluteString];
    if (![pathInModel containsString:@"drafts"]) {
        // use music in draft folder, or clip will fail because of different object
        NSString *musicName = [publishModel.repoMusic.music.loaclAssetUrl lastPathComponent];
        NSString *draftMusicPath = [NSString stringWithFormat:@"%@/%@", publishModel.repoDraft.draftFolder, musicName];
        NSURL *musicURL = [NSURL URLWithString:draftMusicPath];
        
        publishModel.repoMusic.music.loaclAssetUrl = musicURL;
        publishModel.repoMusic.bgmAsset = [AVAsset assetWithURL:musicURL];
    }
    
    publishModel.repoMusic.bgmClipRange = [self p_currentAudioDuration:videoData];
    
    // reset clip panel position
    HTSAudioRange audioRange= {0};
    audioRange.location = 0.f;
    audioRange.length = publishModel.repoMusic.bgmClipRange.durationSeconds;
    publishModel.repoMusic.audioRange = audioRange;
}

- (IESMMVideoDataClipRange *)p_currentAudioDuration:(ACCNLEEditVideoData *)videoData
{
    if (!videoData) {
        return nil;
    }
    
    return IESMMVideoDataClipRangeMake(0.f, videoData.totalVideoDuration);
}

#pragma mark - Tracker
- (void)p_trackSmartMovieButtonClicked:(ACCSmartMovieSceneMode)toMode
                          publishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params[@"click_type"] = (toMode == ACCSmartMovieSceneModeSmartMovie) ? @"on" : @"off";
    params[@"shoot_way"] = @"system_upload";
    params[@"creation_id"] = publishModel.repoContext.createId ?: @"";
    params[@"enter_from"] = @"video_edit_page";
    params[@"content_type"] = @"slideshow";
    params[@"content_source"] = @"upload";
    params[@"is_multi_content"] = @1;
    params[@"music_selected_from"] = @"slideshow_rec";
    params[@"music_id"] = publishModel.repoMusic.music.musicID ?: @"";
    params[@"pic_cnt"] = @([publishModel.repoUploadInfo.selectedUploadAssets count]);
    
    [ACCTracker() trackEvent:@"click_smart_entrance" params:[params copy]];
}

#pragma mark - Getter
- (ACCBarItem<ACCEditBarItemExtraData *>* )smartMovieBarItem {
    ACCBarItemResourceConfig *config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarSmartMovieContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData *> *barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.location = config.location;
    barItem.itemId = ACCEditToolBarSmartMovieContext;
    barItem.imageName = config.imageName;
    barItem.selectedImageName = config.selectedImageName;
    barItem.type = ACCBarItemFunctionTypeDefault;
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        UIButton *ret = [self resetBarItem:itemView toState:ACCSmartMovieBarItemStateReverse];
        if (ret) {
            [self onBarItemButtonClicked:ret];
        }
    };
    barItem.needShowBlock = ^BOOL {
        @strongify(self);
        return acc_isOpenSmartMovieCapabilities([self publishModel]);
    };
    barItem.barItemViewConfigBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if ([self isSmartMovieMode]) {
            [self resetBarItem:itemView toState:ACCSmartMovieBarItemStateOn];
        }
    };
    barItem.showBubbleBlock = ^{
        @strongify(self);
        [self showBubbleTipsIfNeeded];
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeSmartMovie];
    return barItem;
}

- (UIButton *)smartMovieBarItemButton
{
    return [self.viewContainer viewWithBarItemID:ACCEditToolBarSmartMovieContext].button;
}

- (ACCEditSmartMovieViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCEditSmartMovieViewModel.class];
        NSAssert(_viewModel, @"should not be nil");
    }
    return _viewModel;
}

- (ACCEditViewControllerInputData *)inputData
{
    return [self viewModel].inputData;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return [self viewModel].inputData.publishModel;
}
  
- (id<ACCSmartMovieManagerProtocol>)smManager
{
    if (!_smManager) {
        _smManager = acc_sharedSmartMovieManager();
    }
    return _smManager;
}

@end
