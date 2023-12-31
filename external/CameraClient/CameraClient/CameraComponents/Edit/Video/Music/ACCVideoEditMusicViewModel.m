//
//  ACCVideoEditMusicViewModel.m
//  CameraClient
//
//  Created by liuqing on 2020/2/23.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import "ACCVideoEditMusicViewModel.h"
#import "AWEAIMusicRecommendManager.h"
#import "ACCVideoMusicProtocol.h"
#import "AWEMusicSelectItem.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CameraClient/ACCCommerceServiceProtocol.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import "AWEVideoPublishMusicSelectUserCollectionsReqeustManager.h"
#import <CreationKitRTProtocol/ACCEditAudioEffectProtocol.h>
#import "AWEMVTemplateModel.h"
#import "AWEPhotoMovieManager.h"
#import <CreationKitArch/ACCRepoMVModel.h>
#import "ACCVideoEditVolumeChangeContext.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import "ACCFriendsServiceProtocol.h"
#import "ACCVideoMusicListResponse.h"
#import "AWERepoPublishConfigModel.h"
#import "ACCCommerceServiceProtocol.h"
#import "ACCEditMusicBizModule.h"

// 卡点信息
#import "ACCMVAudioBeatTrackManager.h"
#import "AWERepoMVModel.h"

#import "ACCVideoEditMusicConfigProtocol.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCToastProtocol.h>

#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/ACCRepoTextModeModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import "ACCVideoEditMusicViewModel+ACCSelectMusic.h"
#import "AWEEditAlgorithmManager.h"

// 智能照片电影
#import <CameraClient/ACCEditSmartMovieProtocol.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/ACCSmartMovieManagerProtocol.h>
#import <CameraClient/ACCSmartMovieUtils.h>
#import <CameraClient/ACCEditSmartMovieMusicTuple.h>
#import "ACCRepoSmartMovieInfoModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

ACCContextId(ACCVideoEditMusicContext)

static NSString * const kAWENormalVideoEditMusicPanelShownKey = @"AWENormalVideoEditMusicPanelShown";

@interface ACCVideoEditMusicViewModel ()

@property (nonatomic, strong) RACSubject *willSelectMusicSubject;
@property (nonatomic, strong) RACSubject *didDeselectMusicSubject;
@property (nonatomic, strong) RACSubject *musicChangedSubject;
@property (nonatomic, strong) RACSubject<id<ACCMusicModelProtocol>> *didRequestMusicSubject;
@property (nonatomic, strong) RACSubject<id<ACCMusicModelProtocol>> *didUpdateChallengeModelSubject;
@property (nonatomic, strong) RACSubject<RACThreeTuple<ACCEditVideoData *, id<ACCMusicModelProtocol>, AVURLAsset *> *> *mvWillAddMusicSubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *didAddMusicSubject;
@property (nonatomic, strong) RACSubject<NSNumber *> *mvDidChangeMusicSubject;
@property (nonatomic, strong) RACSubject<NSValue *> *didSelectCutMusicSubject;
@property (nonatomic, strong) RACSubject *willAddMusicSubject;

@property (nonatomic, strong) RACSubject<NSNumber *> *mvChangeMusicLoadingSubject;
@property (nonatomic, strong) RACSubject<NSString *> *changeMusicTipsSubject;
@property (nonatomic, strong) RACSubject *collectedMusicListSubject;
@property (nonatomic, strong) RACSubject *volumeChangedSubject;
@property (nonatomic, strong) RACSubject *refreshVolumeViewSubject;
@property (nonatomic, strong) RACBehaviorSubject *refreshMusicRelatedUISubject;
@property (nonatomic, strong) RACSubject *cutMusicButtonClickedSubject;

@property (nonatomic, strong) RACSubject <RACTwoTuple<NSString *, NSError *> *> *featchFramesUploadStatusSubject;

@property (nonatomic, copy) NSArray<AWEMusicSelectItem *> *musicList;
@property (nonatomic, copy) NSArray<AWEMusicSelectItem *> *userCollectedMusicList;
@property (nonatomic, strong) AWEVideoPublishMusicSelectUserCollectionsReqeustManager *userMusicCollectionReqManager;
@property (nonatomic, assign) BOOL isRetryingFetchUserCollectedMusic;
@property (nonatomic, assign, readwrite) BOOL musicFeatureDisable;
@property (nonatomic, strong) id<ACCMusicModelProtocol> musicWhenEnterEditPage;
@property (nonatomic, strong) id<ACCMusicModelProtocol> challengeOrPropMusic;
@property (nonatomic, assign) BOOL hasStartFetchZipURI;
@property (nonatomic, assign) BOOL hasFetchingZipURL;
@property (nonatomic, assign) BOOL hasFetchZipURI; // 是否满足用于音乐推荐条件
@property (nonatomic, assign) BOOL hasFetchFrameZipURI; //  是否满足用于抽帧推荐的条件
@property (nonatomic, assign) BOOL hasShowMusicPanel;
@property (nonatomic, assign) BOOL needResetInitialMusic;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@property (nonatomic, weak) id<ACCEditSmartMovieProtocol> smartMovieService;
// for mew music panel
@property (nonatomic, strong) ACCRecommendMusicRequestManager *recommendMusicRequestManager;
@property (nonatomic, strong) ACCMusicPanelViewModel *musicPanelViewModel;

// for SmartMovie
@property (nonatomic, copy) void(^didSwitchMusicForSmartMovieCompletionCallback) (void);
@property (nonatomic, assign) BOOL removeMusicStickerForSmartMovie;

@property (nonatomic, assign) NSTimeInterval showMusicPanelTime;

@end

@implementation ACCVideoEditMusicViewModel
@synthesize toggleLyricsButtonSubject = _toggleLyricsButtonSubject;

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, smartMovieService, ACCEditSmartMovieProtocol)

- (void)dealloc
{
    [_willSelectMusicSubject sendCompleted];
    [_didDeselectMusicSubject sendCompleted];
    [_didRequestMusicSubject sendCompleted];
    [_mvWillAddMusicSubject sendCompleted];
    [_willAddMusicSubject sendCompleted];
    [_didAddMusicSubject sendCompleted];
    [_mvDidChangeMusicSubject sendCompleted];
    [_didSelectCutMusicSubject sendCompleted];
    [_mvChangeMusicLoadingSubject sendCompleted];
    [_changeMusicTipsSubject sendCompleted];
    [_collectedMusicListSubject sendCompleted];
    [_refreshMusicRelatedUISubject sendCompleted];
    [_volumeChangedSubject sendCompleted];
    [_refreshVolumeViewSubject sendCompleted];
    [_cutMusicButtonClickedSubject sendCompleted];
    [_toggleLyricsButtonSubject sendCompleted];
    [_featchFramesUploadStatusSubject sendCompleted];
    [_musicChangedSubject sendCompleted];
    [_didUpdateChallengeModelSubject sendCompleted];
}

- (instancetype)init {
    self = [super init];
    if (self) {
     
    }
    return self;
}

- (void)fetchFramesAndUPload
{
    [self p_fetchFramesAndUpload];
}

- (void)fetchFramesAndUPloadIfNeeded {
    if (![self.class shouldUploadBachOrFrameForRecommendation]) {
        return;
    }

    if (!self.hasStartFetchZipURI) {
        [self p_fetchFramesAndUpload];
    }
}

- (void)reFetchFramesAndUpload
{
    self.hasShowMusicPanel = NO;
    self.hasStartFetchZipURI = NO;
    [self p_fetchFramesAndUpload];
}

/**
 * 是否应该上传帧用于推荐智能配乐，智能封面，hashtag，小游戏锚点，标题，位置信息等。
 * 基于合规原则，如果用户没有开启预发布开关，不允许在发布之前上传内容。
 * 详见：https://bytedance.feishu.cn/docs/doccneqqafp6k1aTPuLknB9HiSd
 * @return should upload frames for music, groot, cover, hashtag, game, title, poi recommendation.
 */
- (BOOL)shouldUploadFramesForRecommendation
{
    return [[AWEEditAlgorithmManager sharedManager] shouldUploadFramesForRecommendation];
}

+  (BOOL)shouldUploadBachOrFrameForRecommendation { // 抽帧上传(且满足预发布开关) 或 bach都可用于音乐推荐
    return [AWEEditAlgorithmManager sharedManager].recommendStrategy != AWEAIRecommendStrategyNone;
}

/**
 * 如果抽帧推荐功能关闭，先尝试拉取曲库推荐的音乐，如果失败则拉取默认的兜底音乐
 */
- (void)p_fetchHotMusicList
{
    @weakify(self);
    [self.recommendMusicRequestManager fetchInfiniteHotMusic:^{
        @strongify(self);
        [self updateMusicList];
    }];
}

- (void)p_fetchFramesAndUpload
{
    if (self.hasStartFetchZipURI) {
        return;
    }
    self.hasStartFetchZipURI = YES;
    self.hasFetchingZipURL = YES; // groot
    
    // 如果不允许抽帧拉取推荐音乐列表，直接请求热门音乐，降级用兜底
    if (![self.class shouldUploadBachOrFrameForRecommendation]) {
        self.hasFetchingZipURL = NO;  // groot
        [self.featchFramesUploadStatusSubject sendNext:[RACTwoTuple pack:nil :nil]];
        [self p_fetchHotMusicList];
        return;
    }
    
    // 拉取AI推荐配乐列表
    @weakify(self);
    [AWEAIMusicRecommendManager sharedInstance].editService = self.editService;
    [[AWEAIMusicRecommendManager sharedInstance] startFetchFramsAndUploadWithPublishModel:self.publishModel callback:^(NSString * _Nullable URI, AWEAIRecommendStrategy recommendStrategyType, BOOL videoChanged, NSError * _Nullable error) {
        @strongify(self);
        /**
         抽帧策略下会有两种情况：
         1.AWEAIRecommendStrategyUploadFrames：只有抽帧上传推荐的uri进行回调
         2.AWEAIRecommendStrategyBachVector：抽帧上传推荐和bach推荐的uri和分别的进行回调，命中bach同时也会进行1的抽帧上传操作
         注意：命中bach的话会等待bach服务回调进行音乐请求的服务，并使用抽帧上传uri兜底，而物种识别则必须依赖使用抽帧上传的结果
         **/
        if (recommendStrategyType == AWEAIRecommendStrategyBachVector) {  // batch本地模型推荐
            self.hasFetchZipURI = YES; // 允许音乐使用bach推荐
            if (self.hasShowMusicPanel || ACCConfigBool(kConfigBool_studio_edit_music_panel_optimize)) {
                // when bach zip uri fetched after panel showed, need fetch list right now
                [self fetchAIRecommendMuiscListIfNeeded];
            }
        } else {
            self.hasFetchFrameZipURI = YES; // 抽帧上传推荐完成
            self.hasFetchingZipURL = NO;  // groot
            BOOL useBachToRecommend = [[AWEEditAlgorithmManager sharedManager] useBachToRecommend];
            if (!useBachToRecommend) { // 如果未使用bach则直接更新抽帧状态，允许音乐使用抽帧上传推荐
                self.hasFetchZipURI = YES;
                if (self.hasShowMusicPanel || ACCConfigBool(kConfigBool_studio_edit_music_panel_optimize)) {
                    // when  frame zip uri fetched after panel showed, need fetch list right now
                    [self fetchAIRecommendMuiscListIfNeeded];
                }
            }
            // groot物种识别依赖图片的抽帧zipURI，所以只能使用抽帧上传推荐
            [self.featchFramesUploadStatusSubject sendNext:[RACTwoTuple pack:URI :error]];
        }
        
        if (error) {
            AWELogToolError(AWELogToolTagMusic, @"%s AI music fetch frames error: %@, errorFrom:%@",__PRETTY_FUNCTION__ ,error, @(recommendStrategyType));
        }
    }];
}

- (void)generalFetchFramesAndUpload {
    if (self.hasFetchingZipURL) {
        return;
    }
    self.hasFetchingZipURL = YES;
    if (self.publishModel.repoMusic.zipURI || self.hasFetchFrameZipURI) {
        self.hasFetchingZipURL = NO;
        [self.featchFramesUploadStatusSubject sendNext:[RACTwoTuple pack:self.publishModel.repoMusic.zipURI :nil]];
        return;
    }
}

- (void)fetchAIRecommendMuiscListIfNeeded
{
    self.hasShowMusicPanel = YES;
    
    if ([self.recommendMusicRequestManager shouldUseMusicDataFromHost]) {
        [self updateMusicList];
        return;
    }

    // in new edit clip mode, hot music list for the editor page.
    if ([self.repository.repoContext newClipForMultiUploadVideos] && !ACC_isEmptyArray(self.repository.repoMusic.musicList)) {
        [self updateMusicList];
        return;
    }
    
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory &&
        ACCConfigBool(kConfigBool_music_story_enable_download_after_to_edit_page)) {
        return; // 音乐分享无法替换音乐，所以既不需要AI 也不需要 hot music,暂时先包在本次修改的AB中
    }
    
    // recommend music list for the editor page.
      BOOL enableRecommedMusic = [AWEAIMusicRecommendManager sharedInstance].musicFetchType != AWEAIMusicFetchTypeAI || ![AWEAIMusicRecommendManager sharedInstance].recommedMusicList.count;
      if (enableRecommedMusic && [self.class shouldUploadBachOrFrameForRecommendation]) {
          if (self.hasFetchZipURI) {
              if (!self.recommendMusicRequestManager.autoDegradeSelectHotMusic) {
                  @weakify(self);
                  NSString *zipUri = [AWEAIMusicRecommendManager recommendedBachZipUriWithPublishViewModel:self.repository];
                  [self.recommendMusicRequestManager fetchInfiniteAIRecommendMusicWithURI:zipUri isCommercialScene:[IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository] fetchResultBlock:^{
                      @strongify(self);
                      [self updateMusicList];
                  }];
              }
          } else {
              if ([self.recommendMusicRequestManager autoDegradedSelectHotMusicDataSourceSuccess:YES]) { // 降级使用热门音乐是否成功
                  // 已经打开过音乐面板，此时抽帧上传结果还未获取，直接降级切换为热门音乐数据源
                  [self p_fetchHotMusicList];
              }
          }
      }
}

- (void)fetchHotMuiscListIfNeeded
{
    if (![self.repository.repoContext newClipForMultiUploadVideos]) {
        return;
    }
    
    if (!ACC_isEmptyArray(self.repository.repoMusic.musicList)) {
        return;
    }
    // 多段裁减，不适用loadmore音乐
    [[AWEAIMusicRecommendManager sharedInstance] fetchAIRecommendMusicWithURI:nil callback:^(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error) {
        if (musicList.count > 0) {
            self.repository.repoMusic.musicList = [musicList copy];
        }
        
        if (error) {
            AWELogToolError(AWELogToolTagMusic, @"[new edit clip][hot music] %@", error);
        }
    }];
}

- (void)updateMusicList
{
    NSArray<id<ACCMusicModelProtocol>> *musicModels = nil;
    if ([self.recommendMusicRequestManager shouldUseMusicDataFromHost]) {
        musicModels = [self getVideoEditMusicModelsFromHost];
    } else if ([self.repository.repoContext newClipForMultiUploadVideos] && !ACC_isEmptyArray(self.repository.repoMusic.musicList)) {
        musicModels = [self.repository.repoMusic.musicList copy];
    } else {
        BOOL autoDegradeSelectHotMusic = self.recommendMusicRequestManager.autoDegradeSelectHotMusic;
        if (!ACC_isEmptyArray([AWEAIMusicRecommendManager sharedInstance].recommedMusicList) && !autoDegradeSelectHotMusic) {
            musicModels = [[AWEAIMusicRecommendManager sharedInstance].recommedMusicList copy];
        } else {
            musicModels = [self.repository.repoMusic.musicList copy];
        }
    }
    
    // 新音乐面板不需要置顶选中的音乐至音乐列表首位
    BOOL enableMusicPanelVertical = [self.musicPanelViewModel enableMusicPanelVertical];
    NSMutableArray <AWEMusicSelectItem *> *musicItems = [AWEMusicSelectItem itemsForMusicList:musicModels currentPublishModel:self.publishModel musicListExiestMusicOnTop:!enableMusicPanelVertical];
    // 如果mv有默认音乐，插入到AI推荐音乐的首位
    id<ACCMusicModelProtocol> templateMusic = self.repository.repoMV.mvMusic;
    id<ACCMusicModelProtocol> photoToVideoMusic = [self.repository.repoContext shouldSelectMusicAutomatically] ? [[AWEMVTemplateModel sharedManager] videoMusicModelWithType:self.repository.repoContext.photoToVideoPhotoCountType] : nil;
    if (!photoToVideoMusic && !templateMusic) {
        // 普通录制和单段视频上传自动加载推荐音乐
        if ([self shouldRecordAutomaticSelectMusic] || [self shouldImportAutomaticSelectMusic]) {
            photoToVideoMusic = [[AWEMVTemplateModel sharedManager] videoMusicModelWithType:AWEPhotoToVideoPhotoCountTypeNone];
        }
    }
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo &&
        (self.repository.repoProp.propBindMusicIDArray || self.repository.repoChallenge.challenge.connectMusics)) {
        // prop and challenge photo video can't show other reason recommend
        templateMusic = nil;
        photoToVideoMusic = nil;
    }
    
    id<ACCMusicModelProtocol> recommendedMusic = templateMusic ?: (self.challengeOrPropMusic ?: photoToVideoMusic);
    
    // 符合智照条件的情况下，不需要其他的推荐音乐
    if ([ACCSmartMovieABConfig isOn]) {
        // TODO: 优化智照场景判断条件 @leonzou
        if (self.publishModel.repoUploadInfo.selectedUploadAssets.count > 1 &&
            [ACCSmartMovieUtils isAllPhotoAsset:self.publishModel.repoUploadInfo.selectedUploadAssets] &&
            self.publishModel.repoSmartMovie.assetPaths) {
            recommendedMusic = nil;
        }
    }
    
    if (recommendedMusic) {
        NSArray *musicItemsCopy = [musicItems copy];
        // 去重音乐列表中的重复推荐歌曲
        for (AWEMusicSelectItem *item in musicItemsCopy) {
            if ([item.musicModel.musicID isEqualToString:recommendedMusic.musicID]) {
                [musicItems removeObject:item];
            }
            if (item.isRecommended) {
                item.isRecommended = NO;
            }
        }
        
        AWEMusicSelectItem *musicItem = [[AWEMusicSelectItem alloc] init];
        musicItem.isRecommended = YES;
        if (self.publishModel.repoContext.videoType == AWEVideoTypeOneClickFilming) {
            musicItem.isRecommended = NO;
        }
        musicItem.musicModel = recommendedMusic;
        if (musicItem.musicModel.loaclAssetUrl) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[musicItem.musicModel.loaclAssetUrl path]]) {
                musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
            }
        }
        
       // 将推荐音乐强插至音乐列表第一位
        [musicItems acc_insertObject:musicItem atIndex:0];
    } else if (self.musicWhenEnterEditPage && [AWEMusicSelectItem canTransMusicItem:self.musicWhenEnterEditPage]) {
        //进编辑页前配好了音乐
        AWEMusicSelectItem *musicItem = [[AWEMusicSelectItem alloc] init];
        musicItem.musicModel = self.musicWhenEnterEditPage;
        musicItem.isRecommended = musicItem.musicModel.showRecommendLabel;
        if (musicItem.musicModel.loaclAssetUrl) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[musicItem.musicModel.loaclAssetUrl path]]) {
                musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
            } else if (self.musicWhenEnterEditPage.isLocalScannedMedia){
                self.musicWhenEnterEditPage.loaclAssetUrl = self.musicWhenEnterEditPage.originLocalAssetUrl;
                musicItem.status = AWEPhotoMovieMusicStatusDownloaded;
            }
        }
        if (self.publishModel.repoMusic.music) {
            if (![self.publishModel.repoMusic.music isEqual:self.musicWhenEnterEditPage]
                && musicItems.count > 1
                && ![musicItems[1].musicModel isEqual:self.musicWhenEnterEditPage]) {
                if (enableMusicPanelVertical) {
                    // 新音乐面板不强插选中音乐到第一位，如果第一位不是推荐音乐则强插推荐音乐到第一位
                    if (![musicItems[0].musicModel isEqual:self.musicWhenEnterEditPage]) {
                        [musicItems btd_insertObject:musicItem atIndex:0];
                    }
                } else {
                    // 已经选中了歌曲，如果有外部有带入的音乐，则强插至第二位
                    // 1.选中的音乐不为外部带入音乐 2.音乐数量大于1   3.列表中的第二个音乐不为强插的音乐则插入第二位
                    [musicItems btd_insertObject:musicItem atIndex:1];
                }
            }
        } else {
            if (musicItems.count && ![musicItems[0].musicModel isEqual:self.musicWhenEnterEditPage]) {
                [musicItems btd_insertObject:musicItem atIndex:0];
            }
        }
    }
    self.musicList = musicItems;
}

- (ACCVideoEditSelectMusicType)selectMusic
{
    [self.willSelectMusicSubject sendNext:nil];
    return self.useMusicSelectPanel ? [self selectMusicInPanel] : [self selectMusicInLibrary];
}

- (ACCVideoEditSelectMusicType)selectMusicInPanel {
    [self resetUserMusicCollectionData];
    [self fetchUserMusicCollectionDataWithCompletion:nil];
    return ACCVideoEditSelectMusicTypePanel;
}

- (ACCVideoEditSelectMusicType)selectMusicInLibrary
{
    ACCVideoEditSelectMusicType type = ACCVideoEditSelectMusicTypeLibrary;

    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    if (referExtra[@"enter_from"] == nil) {
        referExtra[@"enter_from"] = @"video_edit_page";
    }
    [ACCTracker() trackEvent:@"change_music" params:referExtra needStagingFlag:NO];
    
    return type;
}

- (NSArray<id<ACCChallengeModelProtocol>> *)currentBindChallenges
{
    // 这里音乐challenge因为是从音乐那里fetch来的 所以咱保持原有的话题详情的fetch的逻辑
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.music;
    
    if (!ACC_isEmptyString(music.challenge.challengeName) || !ACC_isEmptyString(music.challenge.itemID)) {
        return @[music.challenge];
    }
    return nil;
}

- (void)deselectMusic:(id<ACCMusicModelProtocol>)music {
    [self deselectMusic:music autoPlay:YES];
}

- (void)deselectMusic:(id<ACCMusicModelProtocol>)music autoPlay:(BOOL)autoPlay {
    [self deselectMusic:music autoPlay:autoPlay completeBlock:nil];
}

- (void)deselectMusic:(id<ACCMusicModelProtocol>)music autoPlay:(BOOL)autoPlay completeBlock:(void (^)(void))completeBlock {
    self.repository.repoMusic.musicSelectedFrom = nil;
    self.repository.repoMusic.music = nil;
    NSURL *url = nil;
    
    @weakify(self);
    [self replaceAudio:url completeBlock:^{
        @strongify(self);
        [self.didDeselectMusicSubject sendNext:nil];
        ACCBLOCK_INVOKE(completeBlock);
    }];
    [self pause];
  
    [self seekToTimeAndRender:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
        @strongify(self);
        if (autoPlay) {
            [self play];
        }
    }];
}

- (void)handleSelectMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error removeMusicSticker:(BOOL)removeMusicSticker completeBlock:(void (^)(void))completeBlock {
    if (error) {
        AWELogToolError(AWELogToolTagEdit|AWELogToolTagMV, @"[new edit clip] %@", error);
    }
    
    if ([music isEqual:self.repository.repoMusic.music]) {
        return;
    }
    
    if (!error && music.loaclAssetUrl) {
        [self.willAddMusicSubject sendNext:nil];
        BOOL isMusicEffectMV = [self isEffectMusicMV]; // mv影集-音乐动效
        BOOL isAudioBeatTrackMusicMV = [self isAudioBeatTrackMusicMV]; // mv影集-卡点audioBeatTrack模板
        
        // effect同学(@文杰)给的结论是优先走【音乐动效】, 且【音乐动效】和【audioBeatTrack卡点】互斥
        if (isMusicEffectMV) {
            // mv影集-音乐动效
            [self updateMusicOfMusicEffectMV:music removeMusicSticker:removeMusicSticker];
        } else if (isAudioBeatTrackMusicMV) {
            // mv影集-卡点audioBeatTrack模板
            [self updateMusicWithAudioBeatTrack:music removeMusicSticker:removeMusicSticker];
        } else {
            [self updateMusicOfNormalVideo:music
                        removeMusicSticker:removeMusicSticker
                             completeBlock:^{
                ACCBLOCK_INVOKE(completeBlock);
            }];
        }
        
        [self requestMusicDetailIfNeeded:music];
    }
}

- (void)handleSelectMusic:(id<ACCMusicModelProtocol>)music error:(NSError *)error removeMusicSticker:(BOOL)removeMusicSticker {
    [self handleSelectMusic:music error:error removeMusicSticker:removeMusicSticker completeBlock:nil];
}

- (void)updateMusicOfMusicEffectMV:(id<ACCMusicModelProtocol>)music removeMusicSticker:(BOOL)removeMusicSticker
{
    ACCEditMVModel *mvModel = self.repository.repoMV.mvModel;
    ACCEditVideoData *videoData = self.repository.repoVideoInfo.video;
    ACCEditVideoData *editBufferVideoData = [videoData copy]; // 编辑缓冲区数据，编辑成功后替换掉 publishViewMode.video 和 player的videoData，失败直接废弃
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:music.loaclAssetUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    Float64 duration = CMTimeGetSeconds(audioAsset.duration);
    if (mvModel && editBufferVideoData && audioAsset && duration > 0) {
        editBufferVideoData.audioAssets = @[audioAsset];
        
        [self.mvWillAddMusicSubject sendNext:[RACThreeTuple pack:editBufferVideoData :music :audioAsset]];
        
        // TODO: @edit二期 消息发送，让playerService响应
        // 2. 暂停播放
        [self pause];
        
        [self.mvChangeMusicLoadingSubject sendNext:@(YES)];
        id<ACCMusicModelProtocol>  previousMusic = self.repository.repoMusic.music;
        // bugfix: set firstly before change music successful, else will cause `[self.viewModel updateMusicList]` error. set these two values back if mv changed failed.
        self.repository.repoMusic.music = music;
        @weakify(self);
        [mvModel userChangeMusic:editBufferVideoData completion:^(BOOL result, NSError *error, ACCEditVideoData *info) {
            @strongify(self);
            if (result && info) {
                [self.repository.repoVideoInfo updateVideoData:info];
                self.repository.repoMusic.bgmAsset = audioAsset;
                [self.editService.audioEffect setBgmAsset:audioAsset];
                 [self updateVideoData:info
                            updateType:VEVideoDataUpdateBGMAudio
                         completeBlock:^(NSError * _Nonnull error) {
                     // 更换音乐后，视频时长发生变化，此处需要更新裁剪音乐按钮的状态
                     [self musicEffectMVDidFinishSelectMusic];
                     // 重新播放
                     [self play];
                    
                     if (error) {
                         AWELogToolError2(@"edit", AWELogToolTagEdit, @"music update video data failed: %@", error);
                     }
                 }];
                [self.didAddMusicSubject sendNext:@(removeMusicSticker)];
            } else {
                [self.mvChangeMusicLoadingSubject sendNext:@(NO)];
                // mv音乐动效生成失败，给出提示
                AWELogToolError(AWELogToolTagEdit|AWELogToolTagMV, @"Set music failed. %@", error);
                [self.changeMusicTipsSubject sendNext:ACCLocalizedString(@"mv_music_change_fail", @"音乐更换失败，请重试")];
                self.repository.repoMusic.music = previousMusic;
                [self.mvDidChangeMusicSubject sendNext:@(NO)];
                [self play];
            }
        }];
    } else {
        AWELogToolError(AWELogToolTagEdit|AWELogToolTagMV, @"Set music failed. <music: %@>, <music duration: %@>", audioAsset, @(duration));
        [self.changeMusicTipsSubject sendNext:ACCLocalizedString(@"mv_music_change_fail", @"音乐更换失败，请重试")];
    }
}

- (void)updateMusicOfNormalVideo:(id<ACCMusicModelProtocol>)music removeMusicSticker:(BOOL)removeMusicSticker completeBlock:(void (^ __nullable)(void))completeBlock
{
    [self.mvWillAddMusicSubject sendNext:nil];
    id<ACCMusicModelProtocol> oldMusic = self.repository.repoMusic.music;
    self.repository.repoMusic.music = music;
    if (AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        if ([self.smartMovieService isSmartMovieMode]) {
            [self replaceAudioForSmartMovieMusicTo:music
                                              from:oldMusic
                                removeMusicSticker:removeMusicSticker
                                     completeBlock:completeBlock];
        } else {
            if ([ACCSmartMovieABConfig isOn]) {
                self.repository.repoSmartMovie.musicForMV = music;
            }
            [self replaceAudioForPhotoVideo:music.loaclAssetUrl completeBlock:^{
                ACCBLOCK_INVOKE(completeBlock);
            }];
            [self.didAddMusicSubject sendNext:@(removeMusicSticker)];
        }
    } else {
        [self replaceAudio:music.loaclAssetUrl completeBlock:^{
            ACCBLOCK_INVOKE(completeBlock);
        }];
        [self.didAddMusicSubject sendNext:@(removeMusicSticker)];
    }
}

- (void)markShowIfNeeded
{
    if ([AWEAIMusicRecommendManager sharedInstance].musicFetchType == AWEAIMusicFetchTypeAI) {
        [ACCCache() setBool:YES forKey:kAWENormalVideoEditMusicPanelShownKey];
    }
}

- (void)sendSmartMovieDidAddMusicSignal
{
    if (self.didSwitchMusicForSmartMovieCompletionCallback) {
        ACCBLOCK_INVOKE(self.didSwitchMusicForSmartMovieCompletionCallback);
        [self.didAddMusicSubject sendNext:@(self.removeMusicStickerForSmartMovie)];
        self.removeMusicStickerForSmartMovie = NO;
        self.didSwitchMusicForSmartMovieCompletionCallback = nil;
    }    
}

- (void)resetCollectedMusicListIfNeeded
{
    [self.collectedMusicListSubject sendNext:nil];
    [self.userMusicCollectionReqManager resetRequestParams];
}

- (void)setNeedResetInitialMusic:(BOOL)needResetInitialMusic
{
    _needResetInitialMusic = needResetInitialMusic;
}

- (void)handleSmartMVInitialMusic:(id<ACCMusicModelProtocol>)music
{
    if (self.needResetInitialMusic) {
        if (music.loaclAssetUrl) {
            [self replaceAudio:music.loaclAssetUrl completeBlock:nil];
            HTSAudioRange range  = self.publishModel.repoMusic.audioRange;
            [self.didAddMusicSubject sendNext:@(YES)]; // will change audio range
            self.publishModel.repoMusic.audioRange = range;
            [self didSelectCutMusicSignal:range];
        }
        self.needResetInitialMusic = NO;
    }
}

#pragma mark -

- (void)fetchUserMusicCollectionDataWithCompletion:(void (^)(BOOL))completion
{
    @weakify(self);
    [self.userMusicCollectionReqManager fetchCurrPageModelsWithCompletion:^(BOOL success, ACCMusicCollectListsResponseModel *_Nonnull rspModel) {
        @strongify(self);
        if (success) {
            self.userCollectedMusicList = [self generateUserCollectedMusicListWithRspModel:rspModel];
            [self.collectedMusicListSubject sendNext:self.userCollectedMusicList];
        } else {
            if (self.userMusicCollectionReqManager.curr == 0) {
                [self.collectedMusicListSubject sendNext:nil];
            }
        }
        ACCBLOCK_INVOKE(completion, success);
    }];
}

- (void)resetUserMusicCollectionData
{
    [self.userMusicCollectionReqManager resetRequestParams];
    self.userCollectedMusicList = @[];
}

- (NSMutableArray<AWEMusicSelectItem *> *)generateUserCollectedMusicListWithRspModel:(ACCMusicCollectListsResponseModel *)rspModel
{
    NSMutableArray<AWEMusicSelectItem *> *list = [NSMutableArray arrayWithArray:self.userCollectedMusicList];
    NSMutableArray<AWEMusicSelectItem *> *arrviedList = [AWEMusicSelectItem itemsForMusicList:rspModel.mcList currentPublishModel:self.publishModel];
    if (arrviedList.count > 0 && arrviedList.count == rspModel.mcList.count + 1) {
        // 说明被插入了currMusic
        [arrviedList removeObjectAtIndex:0];
    }
    [list addObjectsFromArray:arrviedList];
    return list;
}

- (void)requestMusicDetailIfNeeded:(id<ACCMusicModelProtocol>)music
{
    if (music.musicID.length && self.repository.repoMusic.music.challenge == nil) {
        [IESAutoInline(self.serviceProvider, ACCMusicNetServiceProtocol) requestMusicItemWithID:music.musicID completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
            if ([model.musicID isEqualToString:self.repository.repoMusic.music.musicID]) {
                //如果新选的音乐带有挑战,往标题后面拼接
                [self.didRequestMusicSubject sendNext:model];
            }
            
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
            }
        }];
    }
}

- (void)musicEffectMVDidFinishSelectMusic
{
    // 动效音乐MV影集的音乐会在这里设置，这时候audioAssets只有bgm
    self.repository.repoMusic.bgmAsset = self.videoData.audioAssets.firstObject;
    
    [self.mvDidChangeMusicSubject sendNext:@(YES)];
    // 取消loading弹窗
    [self.mvChangeMusicLoadingSubject sendNext:@(NO)];
}

- (void)collectMusic:(id<ACCMusicModelProtocol>)music collect:(BOOL)collect
{
    if (music == nil) {
        return;
    }
    if (collect == music.isFavorite) {
        return;
    }
    music.isFavorite = !music.isFavorite;
    
    [ACCVideoMusic() requestCollectingMusicWithID:music.musicID collect:collect completion:^(BOOL success, NSString * _Nullable message, NSError * _Nullable error) {
        if (success) {
            if (ACC_isEmptyString(message)) {
                message = collect ? ACCLocalizedCurrentString(@"added_to_favorite") : ACCLocalizedCurrentString(@"com_mig_remove_from_favorites_d5lhe7");
            }
            [ACCToast() show:message];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                music.isFavorite = !music.isFavorite;
                
                NSString *hintNamed = collect ? ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later_w6cpxj", @"网络不给力，收藏音乐失败") : ACCLocalizedString(@"com_mig_couldnt_connect_to_the_internet_try_again_later", @"网络不给力，取消收藏失败");
                [ACCToast() show:hintNamed];
            });
        }
    }];
    
    NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
    [params addEntriesFromDictionary:@{@"enter_method" : [NSString stringWithFormat:@"edit_page_%@", music.musicSelectedFrom ],
                                       @"music_id": music.musicID ?: @""}];
    [ACCTracker() trackEvent:collect ? @"favourite_song" : @"cancel_favourite_song" params:params];
}

- (void)updateCollectStateWithMusicId:(NSString *)musicId collect:(BOOL)collect
{
    if (ACC_isEmptyString(musicId)) {
        return;
    }
    [self.musicList enumerateObjectsUsingBlock:^(AWEMusicSelectItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.musicModel.musicID isEqualToString:musicId]) {
            obj.musicModel.isFavorite = collect;
            *stop = YES;
        }
    }];
}

- (void)updateMusicFeatureDisable:(BOOL)disable
{
    _musicFeatureDisable = disable;
}

- (void)updateChallengeOrPropRecommendMusic:(id<ACCMusicModelProtocol>)music
{
    self.challengeOrPropMusic = music;
}

- (void)didSelectCutMusicSignal:(HTSAudioRange)range
{
    [self.didSelectCutMusicSubject sendNext:[NSValue value:&range withObjCType:@encode(HTSAudioRange)]];
}

- (void)sendMusicChangedSignal
{
    [self.musicChangedSubject sendNext:nil];
}

- (void)sendRefreshMusicRelatedUISignal
{
    [self.refreshMusicRelatedUISubject sendNext:@(YES)];
}

// 音量相关
- (void)sendVoiceVolumeChangedSignal:(HTSVideoSoundEffectPanelView *)panel
{
    [self.volumeChangedSubject sendNext:[ACCVideoEditVolumeChangeContext createWithPanelView:panel changeType:ACCVideoEditVolumeChangeTypeVoice]];
}

- (void)sendMusicVolumeChangedSignal:(HTSVideoSoundEffectPanelView *)panel
{
    [self.volumeChangedSubject sendNext:[ACCVideoEditVolumeChangeContext createWithPanelView:panel changeType:ACCVideoEditVolumeChangeTypeMusic]];
}

- (void)sendRefreshVolumeViewSignal:(HTSVideoSoundEffectPanelView *)panel
{
    [self.refreshVolumeViewSubject sendNext:panel];
}

- (void)sendCutMusicButtonClickedSignal
{
    [self.cutMusicButtonClickedSubject sendNext:nil];
}

- (void)sendDidAddMusicSignal:(BOOL)removeMusicSticker
{
    [self.didAddMusicSubject sendNext:@(removeMusicSticker)];
}

- (void)sendUpdateChallengeModelSignal {
    [self.didUpdateChallengeModelSubject sendNext:self.repository.repoMusic.music];
}

#pragma mark - Getter

- (BOOL)musicPanelShowing
{
    return self.musicPanelShowingProvider ? self.musicPanelShowingProvider() : NO;
}

- (RACSignal *)featchFramesUploadStatusSignal {
    return self.featchFramesUploadStatusSubject;
}

- (RACSubject *)featchFramesUploadStatusSubject {
    if (!_featchFramesUploadStatusSubject) {
        _featchFramesUploadStatusSubject = [RACSubject subject];
    }
    return _featchFramesUploadStatusSubject;
}

- (RACSignal *)refreshMusicRelatedUISignal
{
    return self.refreshMusicRelatedUISubject;
}

- (RACBehaviorSubject *)refreshMusicRelatedUISubject
{
    if (!_refreshMusicRelatedUISubject) {
        _refreshMusicRelatedUISubject = [RACBehaviorSubject subject];
    }
    return _refreshMusicRelatedUISubject;
}

- (RACSignal *)musicChangedSignal
{
    return self.musicChangedSubject;
}

- (RACSubject *)musicChangedSubject
{
    if (!_musicChangedSubject) {
        _musicChangedSubject = [RACSubject subject];
    }
    return _musicChangedSubject;
}

- (RACSignal *)willSelectMusicSignal
{
    return self.willSelectMusicSubject;
}

- (RACSubject *)willSelectMusicSubject
{
    if (!_willSelectMusicSubject) {
        _willSelectMusicSubject = [RACSubject subject];
    }
    return _willSelectMusicSubject;
}

- (RACSignal *)didDeselectMusicSignal
{
    return self.didDeselectMusicSubject;
}

- (RACSubject *)didDeselectMusicSubject
{
    if (!_didDeselectMusicSubject) {
        _didDeselectMusicSubject = [RACSubject subject];
    }
    
    return _didDeselectMusicSubject;
}

- (RACSignal<id<ACCMusicModelProtocol>> *)didRequestMusicSignal
{
    return self.didRequestMusicSubject;
}


- (RACSignal<id<ACCMusicModelProtocol>> *)didUpdateChallengeModelSignal
{
    return self.didUpdateChallengeModelSubject;
}

- (RACSubject<id<ACCMusicModelProtocol>> *)didRequestMusicSubject
{
    if (!_didRequestMusicSubject) {
        _didRequestMusicSubject = [RACSubject subject];
    }
    
    return _didRequestMusicSubject;
}

- (RACSubject<id<ACCMusicModelProtocol>> *)didUpdateChallengeModelSubject
{
    if (!_didUpdateChallengeModelSubject) {
        _didUpdateChallengeModelSubject = [RACSubject subject];
    }
    
    return _didUpdateChallengeModelSubject;
}

- (RACSignal<RACThreeTuple<ACCEditVideoData *, id<ACCMusicModelProtocol>, AVURLAsset *> *> *)mvWillAddMusicSignal
{
    return self.mvWillAddMusicSubject;
}

- (RACSubject<RACThreeTuple<ACCEditVideoData *, id<ACCMusicModelProtocol>, AVURLAsset *> *> *)mvWillAddMusicSubject
{
    if (!_mvWillAddMusicSubject) {
        _mvWillAddMusicSubject = [RACSubject subject];
    }
    return _mvWillAddMusicSubject;
}

- (RACSignal *)willAddMusicSignal
{
    return self.willAddMusicSubject;
}

- (RACSubject *)willAddMusicSubject
{
    if (!_willAddMusicSubject) {
        _willAddMusicSubject = [RACSubject subject];
    }
    return _willAddMusicSubject;
}

- (RACSignal<NSNumber *> *)didAddMusicSignal
{
    return self.didAddMusicSubject;
}

- (RACSubject<NSNumber *> *)didAddMusicSubject
{
    if (!_didAddMusicSubject) {
        _didAddMusicSubject = [RACSubject subject];
    }
    
    return _didAddMusicSubject;
}

- (RACSignal<NSNumber *> *)mvDidChangeMusicSignal
{
    return self.mvDidChangeMusicSubject;
}

- (RACSubject<NSNumber *> *)mvDidChangeMusicSubject
{
    if (!_mvDidChangeMusicSubject) {
        _mvDidChangeMusicSubject = [RACSubject subject];
    }
    return _mvDidChangeMusicSubject;
}

- (RACSignal<NSValue *> *)didSelectCutMusicSignal
{
    return self.didSelectCutMusicSubject;
}

- (RACSubject<NSValue *> *)didSelectCutMusicSubject
{
    if (!_didSelectCutMusicSubject) {
        _didSelectCutMusicSubject = [RACSubject subject];
    }
    return _didSelectCutMusicSubject;
}

- (RACSignal<NSNumber *> *)mvChangeMusicLoadingSignal
{
    return self.mvChangeMusicLoadingSubject;
}

- (RACSubject<NSNumber *> *)mvChangeMusicLoadingSubject
{
    if (!_mvChangeMusicLoadingSubject) {
        _mvChangeMusicLoadingSubject = [RACSubject subject];
    }
    
    return _mvChangeMusicLoadingSubject;
}

- (RACSignal<NSString *> *)changeMusicTipsSignal
{
    return self.changeMusicTipsSubject;
}

- (RACSubject<NSString *> *)changeMusicTipsSubject
{
    if (!_changeMusicTipsSubject) {
        _changeMusicTipsSubject = [RACSubject subject];
    }
    
    return _changeMusicTipsSubject;
}

- (RACSignal<NSArray<AWEMusicSelectItem *> *> *)musicListSignal
{
    return RACObserve(self, musicList);
}

- (RACSignal<NSArray<AWEMusicSelectItem *> *> *)collectedMusicListSignal
{
    return self.collectedMusicListSubject;
}

- (RACSubject *)collectedMusicListSubject
{
    if (!_collectedMusicListSubject) {
        _collectedMusicListSubject = [RACSubject subject];
    }
    
    return _collectedMusicListSubject;
}

- (RACSignal *)volumeChangedSignal
{
    return self.volumeChangedSubject;
}

- (RACSubject *)volumeChangedSubject
{
    if (!_volumeChangedSubject) {
        _volumeChangedSubject = [RACSubject subject];
    }
    return _volumeChangedSubject;
}

- (RACSignal *)refreshVolumeViewSignal
{
    return self.refreshVolumeViewSubject;
}

- (RACSubject *)refreshVolumeViewSubject
{
    if (!_refreshVolumeViewSubject) {
        _refreshVolumeViewSubject = [RACSubject subject];
    }
    return _refreshVolumeViewSubject;
}

- (RACSignal *)cutMusicButtonClickedSignal
{
    return self.cutMusicButtonClickedSubject;
}

- (RACSubject *)cutMusicButtonClickedSubject
{
    if (!_cutMusicButtonClickedSubject) {
        _cutMusicButtonClickedSubject = [RACSubject subject];
    }
    return _cutMusicButtonClickedSubject;
}

- (RACSignal<RACThreeTuple<NSNumber *, NSString *,id<ACCMusicModelProtocol>> *> *)toggleLyricsButtonSignal
{
    return self.toggleLyricsButtonSubject;        
}

- (RACSubject<RACThreeTuple<NSNumber *, NSString *,id<ACCMusicModelProtocol>> *> *)toggleLyricsButtonSubject
{
    if (!_toggleLyricsButtonSubject) {
        _toggleLyricsButtonSubject = [RACSubject subject];
    }
    return _toggleLyricsButtonSubject;
}

- (AWEVideoPublishMusicSelectUserCollectionsReqeustManager *)userMusicCollectionReqManager
{
    if (!_userMusicCollectionReqManager) {
        _userMusicCollectionReqManager = [[AWEVideoPublishMusicSelectUserCollectionsReqeustManager alloc] init];
    }
    return _userMusicCollectionReqManager;
}

- (ACCRecommendMusicRequestManager *)recommendMusicRequestManager {
    if (!_recommendMusicRequestManager) {
        _recommendMusicRequestManager = [[ACCRecommendMusicRequestManager alloc] initWithPublishViewModel:self.repository];        
    }
    return  _recommendMusicRequestManager;
}

- (ACCMusicPanelViewModel *)musicPanelViewModel {
    if (!_musicPanelViewModel) {
        _musicPanelViewModel = [[ACCMusicPanelViewModel alloc] initWithPublishViewModel:self.repository];
    }
    return _musicPanelViewModel;
}

- (BOOL)useMusicSelectPanel
{
    // 命中配乐反转实验组，且不是首投/音频替换场景时，不使用配乐面板
    BOOL enableReverseMusicABTest = self.publishModel.repoPublishConfig.isFirstPost ||
    self.publishModel.repoContext.videoType == AWEVideoTypeReplaceMusicVideo ||
    ACCConfigInt(kACCConfigInt_studio_edit_page_reverse_add_music) != ACCMusicReverseTypeBanSelectMusicPanel;
    return enableReverseMusicABTest && [[AWEAIMusicRecommendManager sharedInstance] aiRecommendMusicEnabledForModel:self.publishModel];
}

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

#pragma mark - public

- (BOOL)canDeselectMusic
{
    BOOL canDeselect = YES;
    if (AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) {
        canDeselect = ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize);
    }
    if (self.repository.repoCutSame.isClassicalMV) {
        canDeselect = NO;
    }
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        canDeselect = ACCConfigBool(kConfigBool_image_mode_support_delete_music);
    }
    return canDeselect;
}

- (BOOL)isCommerceLimitPanel
{
    return [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository];
}

#pragma mark - ACCVideoEditMusicPlayerDelegate

- (void)continuePlay {
    [self.editService.preview continuePlay];
}

- (void)pause {
    [self.editService.preview pause];
}

- (void)play {
    [self.editService.preview play];
}

- (void)replaceAudio:(NSURL *)url completeBlock:(void (^)(void))completeBlock {
    if (ACCConfigBool(ACCConfigBOOL_profile_as_story_enable_silent_publish)) {
        [self.musicBizModule replaceAudio:url completeBlock:completeBlock];
        return;
    }
    
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        ACCBLOCK_INVOKE(completeBlock);
        return;
    }
    
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url
                                                 options:@{
                                                           AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                                           }];
    Float64 playDuration = audioAsset ? CMTimeGetSeconds(audioAsset.duration) : 0;
    if (audioAsset && self.repository.repoMusic.music.shootDuration && [self.repository.repoMusic.music.shootDuration integerValue] > 0) {
        //编辑页播放时长取整(考虑到上下取整)截断修复
        if (ABS(playDuration - [self.repository.repoMusic.music.shootDuration integerValue]) >= 1) {
            playDuration = [self.repository.repoMusic.music.shootDuration floatValue];
        }
    }
    
    if (self.repository.repoVideoInfo.shouldAccommodateVideoDurationToMusicDuration) {
        @weakify(self);
        ACCSinglePhotoOptimizationABTesting canvasPhotoABSettings = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting];
        playDuration = MIN(self.repository.repoMusic.music.duration.doubleValue, playDuration);
        Float64 videoDuration = MIN(MAX(playDuration, canvasPhotoABSettings.minimumVideoDuration), canvasPhotoABSettings.maximumVideoDuration);
        [[self audioEffectService] setBGM:url start:0 duration:playDuration repeatCount:1 completion:^(AVAsset * _Nullable newBGMAsset) {
            @strongify(self);
            self.repository.repoMusic.bgmAsset = newBGMAsset;
        }];
        [self.editService.canvas updateWithVideoInfo:self.repository.repoVideoInfo duration:videoDuration completion:^(NSError * _Nonnull error) {
            @strongify(self);
            self.repository.repoContext.maxDuration = videoDuration;
            self.repository.repoMusic.bgmClipRange = IESMMVideoDataClipRangeMakeV2(self.repository.repoMusic.bgmClipRange.startSeconds, videoDuration, 0, 1);
            [self.editService.preview play];
            [self.editService.audioEffect setAudioClipRange:self.repository.repoMusic.bgmClipRange forAudioAsset:self.repository.repoMusic.bgmAsset];
            ACCBLOCK_INVOKE(completeBlock);
        }];
    } else {
        @weakify(self);
        [[self audioEffectService] setBGM:url start:0 duration:playDuration repeatCount:1 completion:^(AVAsset * _Nullable newBGMAsset) {
            @strongify(self);
            self.repository.repoMusic.bgmAsset = newBGMAsset;
            if (ACCConfigBool(kConfigBool_music_record_audio_da) && newBGMAsset) {
                [self.editService.audioEffect setAudioClipRange:self.repository.repoVideoInfo.delayRange forAudioAsset:newBGMAsset];
            }
            [self.editService.preview play];
            ACCBLOCK_INVOKE(completeBlock);
        }];
    }
}

- (void)replaceAudioForPhotoMovie:(NSURL *)url completeBlock:(void (^ __nullable)(void))completeBlock {
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url
                                                 options:@{
                                                           AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                                           }];
    AVAsset *videoAsset = [[self.repository.repoVideoInfo.video videoAssets] firstObject];
    NSInteger repeatCount = [AWEPhotoMovieManager audioRepeatCountForVideo:videoAsset audioAsset:audioAsset];
    NSTimeInterval clipDuration = audioAsset.duration.value;
    if (audioAsset.duration.timescale > 0) {
        clipDuration /= audioAsset.duration.timescale;
    }

    @weakify(self);
    [[self audioEffectService] setBGM:url start:0 duration:clipDuration repeatCount:repeatCount completion:^(AVAsset * _Nullable newBGMAsset) {
        @strongify(self);
        self.repository.repoMusic.bgmAsset = newBGMAsset;
        ACCBLOCK_INVOKE(completeBlock);
    }];
}

- (void)replaceAudioForPhotoVideo:(NSURL *)url completeBlock:(void (^)(void))completeBlock
{
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url
                                                 options:@{
                                                           AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
                                                           }];
    
    NSTimeInterval clipDuration = audioAsset.duration.value;
    if (audioAsset.duration.timescale > 0) {
        clipDuration /= audioAsset.duration.timescale;
    }
    
    if (self.repository.repoVideoInfo.shouldAccommodateVideoDurationToMusicDuration) {
        @weakify(self);
        ACCSinglePhotoOptimizationABTesting canvasPhotoABSettings = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting];
        clipDuration = MIN(self.repository.repoMusic.music.shootDuration.doubleValue, clipDuration);
        Float64 videoDuration = MIN(MAX(clipDuration, canvasPhotoABSettings.minimumVideoDuration), canvasPhotoABSettings.maximumVideoDuration);
        NSInteger repeatCount = 1;
        if (self.repository.repoVideoInfo.video.totalVideoDuration > clipDuration && clipDuration > 0) {
            repeatCount = (self.repository.repoVideoInfo.video.totalVideoDuration / clipDuration) + 1;
        }
        [[self audioEffectService] setBGM:url start:0 duration:clipDuration repeatCount:repeatCount completion:^(AVAsset * _Nullable newBGMAsset) {
            @strongify(self);
            self.repository.repoMusic.bgmAsset = newBGMAsset;
        }];
        [self.editService.canvas updateWithVideoInfo:self.repository.repoVideoInfo duration:videoDuration completion:^(NSError * _Nonnull error) {
            @strongify(self);
            self.repository.repoContext.maxDuration = videoDuration;
            self.repository.repoMusic.bgmClipRange = IESMMVideoDataClipRangeMakeV2(self.repository.repoMusic.bgmClipRange.startSeconds, videoDuration, 0, 1);
            [self.editService.preview play];
            [self.editService.audioEffect setAudioClipRange:self.repository.repoMusic.bgmClipRange forAudioAsset:self.repository.repoMusic.bgmAsset];
            ACCBLOCK_INVOKE(completeBlock);
        }];
    } else {
        NSInteger repeatCount = 1;
        if (self.repository.repoVideoInfo.video.totalVideoDuration > clipDuration && clipDuration > 0) {
            repeatCount = (self.repository.repoVideoInfo.video.totalVideoDuration / clipDuration) + 1;
        }
        @weakify(self);
        [[self audioEffectService] setBGM:url start:0 duration:clipDuration repeatCount:repeatCount completion:^(AVAsset * _Nullable newBGMAsset) {
            @strongify(self);
            self.repository.repoMusic.bgmAsset = newBGMAsset;
            ACCBLOCK_INVOKE(completeBlock);
        }];
    }
}

- (void)replaceAudioForSmartMovieMusicTo:(id<ACCMusicModelProtocol>)to
                                    from:(id<ACCMusicModelProtocol>)from
                      removeMusicSticker:(BOOL)removeMusicSticker
                           completeBlock:(void (^)(void))completeBlock
{
    self.removeMusicStickerForSmartMovie = removeMusicSticker;
    self.didSwitchMusicForSmartMovieCompletionCallback = completeBlock;
    self.publishModel.repoSmartMovie.musicForSmartMovie = to;
    
    ACCEditSmartMovieMusicTuple *tuple = [[ACCEditSmartMovieMusicTuple alloc] init];
    tuple.to = to;
    tuple.from = from;
    [self.smartMovieService triggerSignalForWillSwitchMusic:tuple];
}

- (void)seekToTimeAndRender:(CMTime)time completionHandler:(nonnull void (^)(BOOL))completionHandler {
    [self.editService.preview seekToTime:time completionHandler:completionHandler];
}

- (void)setVolumeForAudio:(float)volume
{
    [[self audioEffectService] setVolumeForAudio:volume];
}

- (void)updateVideoData:(ACCEditVideoData * _Nullable)videoData updateType:(VEVideoDataUpdateType)updateType completeBlock:(void (^ _Nullable)(NSError * _Nonnull))completeBlock {
    [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:videoData updateType:updateType completeBlock:completeBlock];
}

- (nonnull ACCEditVideoData *)videoData {
    return self.repository.repoVideoInfo.video;
}

- (BOOL)AIMusicDisableWithType:(ACCVideoEditMusicDisableType * _Nullable)typeRef
{
    BOOL disable = NO;
     if (self.repository.repoUploadInfo.videoClipMode == AWEVideoClipModeAI && self.repository.repoContext.videoType != AWEVideoTypeOneClickFilming) {
        if (ACCConfigBool(kConfigBool_enable_new_clips)) {
            disable = NO;
        } else {
            disable = YES;
        }
        if (typeRef) {
            *typeRef = ACCVideoEditMusicDisableTypeAIClip;
        }
    } else {
        NSTimeInterval duration = [self.repository.repoVideoInfo.video totalVideoDuration];
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        if ([config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit) {
            disable = YES;
            if (typeRef) {
                *typeRef = ACCVideoEditMusicDisableTypeLongVideo;
            }
        }
    }
    [self updateMusicFeatureDisable:disable];
    return disable;
}

#pragma mark - AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate

- (BOOL)isProcessingFetchingData
{
    return self.userMusicCollectionReqManager.isProcessing;
}

- (BOOL)hasMore
{
    return self.userMusicCollectionReqManager.hasMore;
}

- (void)fetchNextPage:(AWEUserCollectedMusicFetchCompletion)completion
{
    [self fetchUserMusicCollectionDataWithCompletion:^(BOOL success) {
        ACCBLOCK_INVOKE(completion, success);
    }];
}

- (void)retryFetchFirstPage
{
    if (self.isRetryingFetchUserCollectedMusic) {
        return;
    }
    self.isRetryingFetchUserCollectedMusic = YES;
    [self resetUserMusicCollectionData];
    @weakify(self);
    [self fetchUserMusicCollectionDataWithCompletion:^(BOOL success) {
        @strongify(self);
        self.isRetryingFetchUserCollectedMusic = NO;
    }];
}

#pragma mark - 影集MV卡点

// 更新卡点音乐
- (void)updateMusicWithAudioBeatTrack:(id<ACCMusicModelProtocol>)music removeMusicSticker:(BOOL)removeMusicSticker {
    ACCEditMVModel *mvModel = self.repository.repoMV.mvModel;
    ACCEditVideoData *videoData = self.repository.repoVideoInfo.video;
    ACCEditVideoData *editBufferVideoData = [videoData copy]; // 编辑缓冲区数据，编辑成功后替换掉 publishViewMode.video 和 player的videoData，失败直接废弃
    ACCMVAudioBeatTrackManager *audioBeatTrackManager = self.repository.repoMV.audioBeatTrackManager;
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:music.loaclAssetUrl options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    Float64 duration = CMTimeGetSeconds(audioAsset.duration);
    if (mvModel && editBufferVideoData && audioAsset && duration > 0 && audioBeatTrackManager) {
        // 音乐和剪切范围替换
        editBufferVideoData.audioAssets = @[audioAsset];
        
        [self.mvWillAddMusicSubject sendNext:[RACThreeTuple pack:editBufferVideoData :music :audioAsset]];
    
        // 暂停播放
        [self pause];
        
        // 显示loading
        [self.mvChangeMusicLoadingSubject sendNext:@(YES)];
        
        // 记录上一次数据
        id<ACCMusicModelProtocol> previousMusic = self.repository.repoMusic.music;
        
        // bugfix: set firstly before change music successful, else will cause `[self.viewModel updateMusicList]` error. set these two values back if mv changed failed.
        // 存储新的音乐及rang
        self.repository.repoMusic.music = music;
        
        // MV卡点设置循环播放
        self.repository.repoMV.mvModel.isAudioFitVideoDuration = YES;
            
        // 处理音频卡点逻辑(切换音乐 or 调节音乐range)
        IESEffectModel *effectModel = [[AWEMVTemplateModel sharedManager] effectForPublishModel:self.publishModel];
        float dstDuration = MAX(0, audioBeatTrackManager.dstOut - audioBeatTrackManager.dstIn);
        float srcIn = audioBeatTrackManager.srcIn;
        float srcOut = audioBeatTrackManager.srcOut;
        
        // 获取模板算法本地相对路径
        NSString *modelPath = [audioBeatTrackManager modelRelativePathForAlgorithm];
    
        // 音乐路径
        NSString *musicFileName = audioAsset.URL.relativePath;
        
        // 配置算法
        [IESMMAudioBeatTracking GetResultAsync:[NSURL fileURLWithPath:musicFileName] srcStart:srcIn srcDuration:srcOut dstDuration:dstDuration modelPath:modelPath completion:^(IESMMAudioBeatTracking *audioBeat) {
            
            if (audioBeat == nil) {
                // 取消loading
                [self.mvChangeMusicLoadingSubject sendNext:@(NO)];
                
                // 使用上一次设置的音频信息进行播放
                [self failToChangeMusicWithInfo:previousMusic autoPlay:YES];
                
                return;
            }
            
            // 更新算法
            [self.repository.repoMV.mvModel setBeatTrackingAlgorithmData:audioBeat];
            
            @weakify(self);
            [self.repository.repoMV.mvModel generateMVWithPath:effectModel.filePath repository:self.repository userResourses:mvModel.resources videoData:editBufferVideoData completion:^(BOOL result, NSError *error, ACCEditVideoData *info) {
                @strongify(self);
    
                if (result && info) {
                    
                    [self updateVideoData:info
                               updateType:VEVideoDataUpdateBGMAudio
                            completeBlock:^(NSError * _Nonnull error) {
                        if (error) {
                            AWELogToolError(AWELogToolTagMusic, @"set MV userResourses error: %@",error);
                            // 取消loading
                            [self.mvChangeMusicLoadingSubject sendNext:@(NO)];
                            
                            // 使用上一次设置的音频信息进行播放
                            [self failToChangeMusicWithInfo:previousMusic autoPlay:YES];
                            
                            return;
                        }
                        
                        // 更新视频数据
                        [self.repository.repoVideoInfo updateVideoData:info];
                        
                        // 重新设置BGM
                        self.repository.repoMusic.bgmAsset = audioAsset;
                        [self.editService.audioEffect setBgmAsset:audioAsset];
                        
                        // 更换音乐后，视频时长发生变化，此处需要更新裁剪音乐按钮的状态
                        [self musicEffectMVDidFinishSelectMusic];
                        
                        // 重新播放
                        [self play];
                    }];
                    
                    [self.didAddMusicSubject sendNext:@(removeMusicSticker)];
                } else {
                    // mv音乐动效生成失败，给出提示
                    AWELogToolError(AWELogToolTagEdit|AWELogToolTagMV, @"Set music failed. %@", error);
                    
                    // 取消loading
                    [self.mvChangeMusicLoadingSubject sendNext:@(NO)];
                    
                    // 使用上一次设置的音频信息进行播放
                    [self failToChangeMusicWithInfo:previousMusic autoPlay:YES];
                }
            }];
        }];
    } else {
        AWELogToolError(AWELogToolTagEdit|AWELogToolTagMV, @"Set music failed. <music: %@>, <music duration: %@>", audioAsset, @(duration));
        [self failToChangeMusicWithInfo:nil autoPlay:NO];
    }
}

// 错误处理
- (void)failToChangeMusicWithInfo:(id<ACCMusicModelProtocol> _Nullable)previousMusic autoPlay:(BOOL)autoPlay {
    // 错误弹窗
    [self.changeMusicTipsSubject sendNext:ACCLocalizedString(@"mv_music_change_fail", @"音乐更换失败，请重试")];
    
    if (previousMusic != nil) {
        // 重置上一个音乐片段，并进行播放
        self.repository.repoMusic.music = previousMusic;
        [self.mvDidChangeMusicSubject sendNext:@(NO)];
        if (autoPlay) {
            [self play];
        }
    }
}

#pragma mark - 音乐类型判断

/*
 * 动效音乐模板
 * 测试模板：喜欢的歌
 * 满足条件：
 * 1、模型配置了动效音乐
 * 2、MV是经典影集或者是点+进行拍摄之后生成的
 */
- (BOOL)isEffectMusicMV {
    BOOL isClassicalMV = self.repository.repoCutSame.isClassicalMV; // 经典影集
    BOOL isFromShootEntranceMV = AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType; // 点+进行拍摄之后的MV
    BOOL hasConfigEffectMusic = AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType; // 模型配置了动效音乐
    
    return hasConfigEffectMusic && (isClassicalMV || isFromShootEntranceMV);
}

/*
 * 卡点模板
 * 测试模板：mv卡点照片缩放
 * 满足条件:
 * 1、extra.json配置mv_music_beat_tracking_offline字段且为true
 * 2、MV是经典影集
 */
- (BOOL)isAudioBeatTrackMusicMV {
    if (self.repository.repoMV &&
        (self.repository.repoMV.audioBeatTrackManager == nil)) {
        IESEffectModel *effectModel = [[AWEMVTemplateModel sharedManager] effectForPublishModel:self.publishModel];
        self.repository.repoMV.audioBeatTrackManager = [[ACCMVAudioBeatTrackManager alloc] initWithMVEffectModel:effectModel];
    }
    BOOL hasConfigAudioBeatTrackMusic = self.repository.repoMV.audioBeatTrackManager.isAudioBeatTrack; // 模型配置了卡点信息
    BOOL isClassicalMV = self.repository.repoCutSame.isClassicalMV; // 经典影集
    
    return hasConfigAudioBeatTrackMusic && isClassicalMV;
}

// 获取从外部传入的音乐，而不是采用 AI 配乐
- (NSArray<id<ACCMusicModelProtocol>> *)getVideoEditMusicModelsFromHost
{
    if (![self.recommendMusicRequestManager shouldUseMusicDataFromHost]) {
        return nil;
    }
    let editMusicConfig = IESOptionalInline(ACCBaseServiceProvider(), ACCVideoEditMusicConfigProtocol);
    if ([editMusicConfig respondsToSelector:@selector(getVideoEditMusicModelArray)]) {
        return [[editMusicConfig getVideoEditMusicModelArray] copy];
    }
    return nil;
}

#pragma mark - track

- (void)clickShowMusicPanelTrack {
    self.showMusicPanelTime = CFAbsoluteTimeGetCurrent();
    NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
    [params addEntriesFromDictionary:self.repository.repoTrack.mediaCountInfo];
    params[@"if_upload_frame"] = self.hasFetchZipURI ? @"success" : @"fail";
    [ACCTracker() trackEvent:@"click_music_entrance" params:params needStagingFlag:NO];
}

@end
