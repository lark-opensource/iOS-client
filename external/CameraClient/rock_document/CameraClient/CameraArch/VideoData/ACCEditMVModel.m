//
//  ACCEditMVModel.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import "ACCEditMVModel.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCConfigKeyDefines.h"
#import "NLEEditor_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLETrackMV_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLEModel_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "ACCNLEUtils.h"
#import "AWERepoMusicModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoDraftModel.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRepoDraftModel.h>

#import "AWERepoMVModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoCutSameModel.h"
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import <CreationKitInfra/ACCLogProtocol.h>

#import "ACCSmartMovieManagerProtocol.h"
#import "ACCSmartMovieABConfig.h"
#import "ACCSmartMovieUtils.h"

@interface ACCEditMVModel()

@property (nonatomic, strong) IESMMMVModel *veMVModel;

@property (nonatomic, copy) NSString *draftFolder;
@property (nonatomic, strong) NLETrackMV_OC *mvTrack;
@property (nonatomic, strong) NLETrack_OC *algorithmTrack;

@property (nonatomic, weak) id<ACCSmartMovieManagerProtocol> smManager;

@end
@implementation ACCEditMVModel

+ (NSArray<IESMMMVResource *> *)getMVResourceInfo:(NSString *)modelPath
{
    return [IESMMMVModel getMVResourceInfo:modelPath];
}

- (instancetype)initWithDraftFolder:(NSString *)draftFolder
{
    self = [super init];
    if (self) {
        _draftFolder = [draftFolder copy];
    }
    return self;
}

- (void)generateMVWithPath:(NSString *)modelPath
                repository:(AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
                completion:(ACCMVModelBlock)completion
{
    if ([ACCNLEUtils useNLEWithRepository:repository]) {
        NLEInterface_OC *nle = [ACCNLEUtils nleInterfaceWithRepository:repository];
        NLEModel_OC *nleModel = [[NLEModel_OC alloc] initWithCanvasSize:repository.repoVideoInfo.video.canvasSize];
        [nle.editor setModel:nleModel];
        
        // 配置 MV Track
        [self.mvTrack updateWithModelPath:modelPath
                            userResources:resources
                        resourcesDuration:nil
                              draftFolder:self.draftFolder];
        [nleModel addTrack:self.mvTrack];
        
        // 更新 MV Track 算法
        if (self.algorithmTrack) {
            [nleModel addTrack:self.algorithmTrack];
        } else {
            // 添加空的 BGM 轨道
            [self p_addPlaceholderMVAudioTrackIfNeeded:nleModel
                                            repository:repository];
        }
        
        // 提交更新
        [nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            if (error == nil) {
                ACCNLEEditVideoData *videoData =
                [[ACCNLEEditVideoData alloc] initWithNLEModel:[nle.editor getModel]
                                                          nle:nle];
                [self p_removePlaceholderMVAudioTrackIfNeeded:nle.editor videoData:videoData];
                !completion ?: completion(YES, nil, videoData);
            } else {
                !completion ?: completion(NO, error, nil);
            }
        }];
        
    } else {
        [self.veMVModel setMV:modelPath
                userResourses:resources
                   completion:^(BOOL result, NSError *error, HTSVideoData *info) {
            !completion ?: completion(result, error, [ACCVEVideoData videoDataWithVideoData:info draftFolder:repository.repoDraft.draftFolder]);
        }];
    }
}

- (void)generateMVWithPath:(NSString *)modelPath
                repository:(nullable AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
                 videoData:(ACCEditVideoData *)videoData
                completion:(ACCMVModelBlock)completion {
    [self generateMVWithPath:modelPath
                  repository:repository
               userResourses:resources
           resourcesDuration:nil
                   videoData:videoData
                  completion:completion];
}

- (void)generateMVWithPath:(NSString *)modelPath
                repository:(nullable AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
         resourcesDuration:(nullable NSArray *)resourcesDuration
                 videoData:(ACCEditVideoData *)videoData
                completion:(ACCMVModelBlock)completion
{
    // 草稿恢复，第一次数据恢复的时候是使用的 ACCVEVideoData，这里需要强制转换为 ACCNLEVideoData
    // FIXME: 如果 MV 模块会内置多条音轨，这里的逻辑会存在 bug
    if (repository != nil && [ACCNLEUtils useNLEWithRepository:repository] && !acc_videodata_is_nle(videoData)) {
        NLEInterface_OC *nle = [ACCNLEUtils createNLEInterfaceIfNeededWithRepository:repository];
        videoData = acc_videodata_make_nle(videoData, nle);
        // 重新恢复 BGM 轨道
        if (repository.repoMusic.bgmAsset) {
            [self p_updateBGMSubtypeForDraftWithRepository:repository videoData:(ACCNLEEditVideoData *)videoData];
        }
    }
    
    acc_videodata_downgrading(videoData, ^(HTSVideoData *veVideoData) {
        [self.veMVModel setMV:modelPath
                userResourses:resources
                    videoData:veVideoData
                   completion:^(BOOL result, NSError *error, HTSVideoData *info) {
            !completion ?: completion(result, error, [ACCVEVideoData videoDataWithVideoData:info  draftFolder:videoData.draftFolder]);
        }];
    }, ^(ACCNLEEditVideoData *videoData) {
        NLEModel_OC *nleModel = videoData.nleModel;
        
        // 动感MV情况下，先移除所有的音轨再配置音乐算法轨
        if (self.algorithmTrack) {
            // 先移除所有的音轨
            [nleModel removeTracksWithType:NLETrackAUDIO];
            // 再配置音乐算法轨
            [nleModel addTrack:self.algorithmTrack];
        } else {
            // 添加空的 BGM 轨道
            [self p_addPlaceholderMVAudioTrackIfNeeded:nleModel
                                            repository:repository];
        }
        
        // 配置 MV Track
        [self.mvTrack updateWithModelPath:modelPath
                            userResources:resources
                        resourcesDuration:resourcesDuration
                              draftFolder:self.draftFolder];
        // 移除再新增主轨
        [nleModel replaceMainTrackWithMV:self.mvTrack];
        
        // 重新设置nleModel给editor
        [videoData.nle.editor setModel:nleModel];
        
        // here update ve mv model, like change karaoke bg image, will generate
        // new ACCEditMVModel, should update it's ve mv model to nle.
        videoData.nle.veMVModel = self.veMVModel;
        
        [videoData.nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            [self p_removePlaceholderMVAudioTrackIfNeeded:videoData.nle.editor videoData:videoData];
            !completion ?: completion(YES, error, videoData);
        }];
    });
}

- (void)generateSmartMovieWithRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                                  assets:(NSArray<NSString *> *_Nonnull)assets
                                 musicID:(NSString *_Nullable)musicID
                           isSwitchMusic:(BOOL)isSwitchMusic
                              completion:(ACCSmartMovieModelBlock _Nullable)completion
{
    if (![ACCSmartMovieABConfig isOn]) {
        NSAssert(NO, @"SmartMovie: smart movie ab is not open!");
        // 必须回调下错误block，否则可能无法移除loading
        AWELogToolError(AWELogToolTagMV, @"SmartMovie: nle or SmartMovie ab not enabled when generate SmartMovie!");
        NSError *error = acc_customExportSmartMovieError();
        ACCBLOCK_INVOKE(completion, NO, nil, error, NO);
        return;
    }
    
    [self.smManager setCurrentScene:ACCSmartMovieSceneModeSmartMovie];
    self.smManager.sceneDataMarker.smartMovieDataExist = YES;
    AWELogToolInfo(AWELogToolTagMV, @"SmartMovie: begin to fetch NLE model");

    if (!isSwitchMusic) {
        [self.smManager fetchMusicListWithAssets:assets];
    }
    
    [self.smManager fetchNLEModelWithAssets:assets
                               musicID:musicID
                         isSwitchMusic:isSwitchMusic
                            completion:^(BOOL isCanceled,
                                         NLEModel_OC * _Nullable model,
                                         NSError * _Nullable error) {
    
        if (isCanceled) {
            ACCBLOCK_INVOKE(completion, YES, nil, error, NO);
        } else if (model) {
            AWELogToolInfo(AWELogToolTagMV, @"SmartMovie: model fetched successfully, begin to process");
            NLEInterface_OC *nle = [ACCNLEUtils nleInterfaceWithRepository:repository];
            [nle.editor setModel:model];
            // 提交更新
            [nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
                if (!error) {
                    ACCNLEEditVideoData *videoData =
                    [[ACCNLEEditVideoData alloc] initWithNLEModel:[nle.editor getModel]
                                                              nle:nle];
                    ACCBLOCK_INVOKE(completion, NO, videoData, nil, NO);
                } else {
                    ACCBLOCK_INVOKE(completion, NO, nil, error, YES);
                }
            }];
        } else {
            AWELogToolError(AWELogToolTagMV, @"SmartMoive: fail to fetch model");
            ACCBLOCK_INVOKE(completion, NO, nil, error, NO);
        }
    }];
}

- (void)userChangePictures:(ACCEditVideoData *)videoData
            newPictureUrls:(NSArray<NSURL *> *)newPictureUrls
                completion:(ACCMVModelBlock)completion
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *veVideoData) {
        [self.veMVModel userChangePictures:veVideoData
                            newPictureUrls:newPictureUrls
                                completion:^(BOOL result, NSError *error, HTSVideoData *info) {
            !completion ?: completion(result, error, [ACCVEVideoData videoDataWithVideoData:info draftFolder:videoData.draftFolder]);
        }];
    }, ^(ACCNLEEditVideoData *videoData) {
        NLEInterface_OC *nle = videoData.nle;
        NLETrackMV_OC *mvTrack = [[videoData.nle.editor getModel] mvTrack];
        // 移除老的 Slots
        [mvTrack.slots acc_forEach:^(NLETrackSlot_OC * _Nonnull obj) {
            [mvTrack removeSlot:obj];
        }];
        // 添加新的 Picture Slots
        [newPictureUrls acc_forEach:^(NSURL * _Nonnull obj) {
            IESMMMVResource *mvResource = [[IESMMMVResource alloc] init];
            mvResource.resourceContent = obj.absoluteString;
            mvResource.resourceType = IESMMMVResourcesType_img;
            NLETrackSlot_OC *slot = [NLETrackSlot_OC mvTrackSlotWithResouce:mvResource draftFolder:self.draftFolder];
            [mvTrack addSlotAtEnd:slot];
        }];

        // 提交修改
        [nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            if (error == nil) {
                ACCNLEEditVideoData *videoData =
                [[ACCNLEEditVideoData alloc] initWithNLEModel:[nle.editor getModel]
                                                          nle:nle];
                !completion ?: completion(YES, nil, videoData);
            } else {
                !completion ?: completion(NO, error, nil);
            }
        }];
    });
}

- (void)userChangeMusic:(ACCEditVideoData *)videoData
             completion:(ACCMVModelBlock)completion
{
    acc_videodata_downgrading(videoData, ^(HTSVideoData *veVideoData) {
        [self.veMVModel userChangeMusic:veVideoData
                             completion:^(BOOL result, NSError *error, HTSVideoData *info) {
            !completion ?: completion(result, error, [ACCVEVideoData videoDataWithVideoData:info draftFolder:videoData.draftFolder]);
        }];
    }, ^(ACCNLEEditVideoData *videoData) {
        NLEModel_OC *nleModel = videoData.nleModel;
        
        NSAssert([nleModel tracksWithType:NLETrackAUDIO].count == 1, @"audio count is unavailable");
        
        NLETrackSlot_OC *audioTrackSlot = nil;
        // 移除音频轨道
        NLETrack_OC *bgmTrack =
        [[nleModel tracksWithType:NLETrackAUDIO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
            return item.isBGMTrack;
        }];
        
        if (bgmTrack) {
            [nleModel removeTrack:bgmTrack];
            audioTrackSlot = bgmTrack.slots.firstObject;
        } else {
            NLETrack_OC *audioTrack = [[nleModel tracksWithType:NLETrackAUDIO] firstObject];
            audioTrackSlot = audioTrack.slots.firstObject;
            [nleModel removeTrack:audioTrack];
        }
        
        if (audioTrackSlot.audioSegment.audioFile.acc_path.length == 0 ||
            nleModel.mvTrack.mv.acc_path.length == 0) {
            !completion ?: completion(NO, nil, nil);
            return;
        }
        
        // 设置动效音乐
        NLETrackSlot_OC *musicSlot =
        [NLETrackSlot_OC mvMusicSlotWithMusicPath:audioTrackSlot.audioSegment.audioFile.acc_path
                                   audioClipRange:audioTrackSlot.audioClipRange
                                      draftFolder:self.draftFolder];
        NLETrack_OC *effectAudioTrack = [[NLETrack_OC alloc] init];
        effectAudioTrack.isBGMTrack = YES;
        [effectAudioTrack addSlot:musicSlot];
        [nleModel addTrack:effectAudioTrack];
        
        NLEInterface_OC *nle = videoData.nle;
        [nle.editor setModel:nleModel];
        
        [nle.editor acc_commitAndRender:^(NSError * _Nullable error) {
            if (error == nil) {
                ACCNLEEditVideoData *videoData =
                [[ACCNLEEditVideoData alloc] initWithNLEModel:[nle.editor getModel]
                                                          nle:nle];
                !completion ?: completion(YES, nil, videoData);
            } else {
                !completion ?: completion(NO, error, nil);
            }
        }];
    });
}

- (void)clearAndAddBGMWithVideoData:(ACCEditVideoData *)videoData
                           bgmAsset:(AVAsset *)bgmAsset
                         repository:(AWEVideoPublishViewModel *)repository
{
    NSAssert(bgmAsset, @"bgmAsset should not be nil");
    acc_videodata_downgrading(videoData, ^(HTSVideoData * _Nonnull videoData) {
        videoData.audioAssets = [@[bgmAsset] mutableCopy];
    }, ^(ACCNLEEditVideoData * _Nonnull videoData) {
        // 移除老的音频轨道
        [videoData.nleModel removeTracksWithType:NLETrackAUDIO];
        // 添加 BGM 音轨
        NLETrack_OC *track = [self p_bgmTrackWithRepository:repository bgmAsset:bgmAsset nle:videoData.nle];
        [videoData.nleModel addTrack:track];
    });
}

- (void)replaceAudioWithVideoData:(ACCEditVideoData *)videoData
                       repository:(AWEVideoPublishViewModel *)repository
{
    if (acc_videodata_is_nle(videoData) &&
        acc_videodata_is_nle(repository.repoVideoInfo.video)) {
        // NLE 逻辑
        ACCNLEEditVideoData *curVideoData = (ACCNLEEditVideoData *)videoData;
        ACCNLEEditVideoData *preVideoData = (ACCNLEEditVideoData *)repository.repoVideoInfo.video;
        
        // 移除老的音频轨道
        [curVideoData.nleModel removeTracksWithType:NLETrackAUDIO];
        [[preVideoData.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
            [curVideoData.nleModel addTrack:obj];
        }];
        [curVideoData.nle.editor acc_commitAndRender:nil];
    } else {
        // VE 逻辑
        videoData.audioAssets = repository.repoVideoInfo.video.audioAssets;
    }
}

- (void)addBGMForDraftWithRepository:(AWEVideoPublishViewModel *)repository
{
    if (!acc_videodata_is_nle(repository.repoVideoInfo.video)) {
        return;
    }
    ACCNLEEditVideoData *curVideoData = (ACCNLEEditVideoData *)repository.repoVideoInfo.video;
    
    if (repository.repoMusic.bgmAsset) {
        NLETrack_OC *track = [self p_bgmTrackWithRepository:repository
                                                   bgmAsset:repository.repoMusic.bgmAsset
                                                        nle:curVideoData.nle];
        [curVideoData.nleModel addTrack:track];
    } else {
        [self p_addPlaceholderMVAudioTrackIfNeeded:curVideoData.nleModel repository:repository];
    }
    
}

#pragma mark - Private

- (NLETrack_OC *)p_bgmTrackWithRepository:(AWEVideoPublishViewModel *)repository
                                 bgmAsset:(AVAsset *)bgmAsset
                                      nle:(NLEInterface_OC *)nle
{
    NSAssert(bgmAsset, @"bgmAsset should not be nil");
    ACCMVAudioType mvAudioType = [self p_audioTypeInMV:repository];
    NLETrackSlot_OC *slot = [NLETrackSlot_OC audioTrackSlotWithAsset:bgmAsset nle:nle];
    if (mvAudioType == ACCMVAudioTypeAudioBeatTracking) {
        slot.audioSegment.getResNode.resourceType = NLEResourceTypeAlgorithmMVAudio;
    } else if (mvAudioType == ACCMVAudioTypeEffectMusic) {
        slot.audioSegment.getResNode.resourceType = NLEResourceTypeMusicMVAudio;
    } else {
        slot.audioSegment.getResNode.resourceType = NLEResourceTypeNormalMVAudio;
    }
    NLETrack_OC *track = [[NLETrack_OC alloc] init];
    track.extraTrackType = NLETrackAUDIO;
    track.isBGMTrack = YES;
    [track addSlot:slot];
    return track;
}

#pragma mark - Properties

- (void)setResolution:(CGSize)resolution
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        self.mvTrack.mvResolution = (resolution.width == 1080) ? NLESegmentMVResolution1080P :NLESegmentMVResolution720P;
    } else {
        self.veMVModel.resolution = resolution;
    }
}

- (void)setVariableDuration:(float)duration
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        // 使用sum(K歌音频轨道segment时长)计算
    } else {
        [self.veMVModel setVariableDuration:duration];
    }
}

- (void)setResourceDurations:(NSArray *)durations
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        // 使用sum(K歌MV主轨时长)计算
    } else {
        [self.veMVModel setResourceDurations:durations];
    }
}

- (NSArray<IESMMMVResource *> *)resources
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        return [self.mvTrack.slots acc_map:^id _Nonnull(NLETrackSlot_OC * _Nonnull obj) {
            return [obj mvResouce];
        }];
    } else {
        return self.veMVModel.resources;
    }
}

- (void)setServerAlgorithmResults:(NSArray<VEMVAlgorithmResult *> *)results
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        NSArray<NLEMVExternalAlgorithmResult_OC *> *nleResults = [results acc_map:^id _Nonnull(VEMVAlgorithmResult * _Nonnull obj) {
            return [ACCEditMVModel nleAlgorithmResultWithVE:obj draftFolder:self.draftFolder];
        }];
        [self.mvTrack setAlgorithmResults:nleResults];
    } else {
        [self.veMVModel setServerAlgorithmResults:results];
    }
}

- (void)setBeatTrackingAlgorithmData:(IESMMAudioBeatTracking *)beatTracking
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        // 配置音乐算法
        [self.mvTrack configAlgorithmPath:beatTracking.modelPath];
        
        // 配置卡点音乐
        NLETrackSlot_OC *trackSlot = [NLETrackSlot_OC slotWithBeatsTracking:beatTracking
                                                                draftFolder:self.draftFolder];
        self.algorithmTrack = [[NLETrack_OC alloc] init];
        self.algorithmTrack.isBGMTrack = YES;
        self.algorithmTrack.smartMovieVideoMode = ACCSmartMovieSceneModeMVVideo;
        [self.algorithmTrack addSlot:trackSlot];
    } else {
        [self.veMVModel setBeatTrackingAlgorithmData:beatTracking];
    }
}

- (void)setIsAudioFitVideoDuration:(BOOL)isAudioFitVideoDuration
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        self.mvTrack.singleVideo = isAudioFitVideoDuration;
    } else {
        self.veMVModel.isAudioFitVideoDuration = isAudioFitVideoDuration;
    }
}

- (BOOL)isAudioFitVideoDuration
{
    if (ACCConfigBool(kConfigBool_studio_edit_use_nle)) {
        return self.mvTrack.singleVideo;
    } else {
        return self.veMVModel.isAudioFitVideoDuration;
    }
}

- (id<ACCSmartMovieManagerProtocol>)smManager
{
    if (!_smManager) {
        _smManager = acc_sharedSmartMovieManager();
    }
    return _smManager;
}

#pragma mark - Utils

+ (NLEMVExternalAlgorithmResult_OC *)nleAlgorithmResultWithVE:(VEMVAlgorithmResult *)ve
                                                  draftFolder:(NSString *)draftFolder
{
    NLEMVExternalAlgorithmResult_OC *nleAlgorithm = [[NLEMVExternalAlgorithmResult_OC alloc] init];
    nleAlgorithm.algorithmName = ve.algorithmName;
    
    if (ve.photoPath.length > 0) {
        NLEResourceNode_OC *photoResouce = [[NLEResourceNode_OC alloc] init];
        [photoResouce acc_setPrivateResouceWithURL:[NSURL URLWithString:ve.photoPath]
                                       draftFolder:draftFolder];
        nleAlgorithm.photo = photoResouce;
    }
    
    if (ve.imagePath.length > 0) {
        NLEResourceNode_OC *imageResouce = [[NLEResourceNode_OC alloc] init];
        [imageResouce acc_setPrivateResouceWithURL:[NSURL URLWithString:ve.imagePath]
                                       draftFolder:draftFolder];
        nleAlgorithm.mask = imageResouce;
    }
    
    switch (ve.algorithmResultType) {
        case VEMVAlgorithmResultInType_Image:
            nleAlgorithm.resultInType = NLESegmentMVResultInTypeImage;
            break;
        case VEMVAlgorithmResultInType_Video:
            nleAlgorithm.resultInType = NLESegmentMVResultInTypeVideo;
            break;
        case VEMVAlgorithmResultInType_Json:
            nleAlgorithm.resultInType = NLESegmentMVResultInTypeJson;
            break;
        default:
            break;
    }
    
    return nleAlgorithm;
}

// 判断是否有BGM，没有的话填充空的音频轨
- (void)p_addPlaceholderMVAudioTrackIfNeeded:(NLEModel_OC *)nleModel
                                  repository:(AWEVideoPublishViewModel *)repository {
    NLETrack_OC *bgmTrack = [[nleModel tracksWithType:NLETrackAUDIO] acc_match:^BOOL(NLETrack_OC * _Nonnull item) {
        return item.isBGMTrack;
    }];
    if (bgmTrack != nil) return;
    
    NLETrack_OC *placeHolderTrack = [[NLETrack_OC alloc] init];
    placeHolderTrack.isBGMTrack = YES;
    placeHolderTrack.smartMovieVideoMode = ACCSmartMovieSceneModeMVVideo;
    BOOL isEffectMV = [ACCEditMVModel p_isEffectMusicMV:repository];
    NLEResourceType resourceType = isEffectMV ? NLEResourceTypeMusicMVAudio : NLEResourceTypeNormalMVAudio;
    [placeHolderTrack addSlot:[NLETrackSlot_OC placeHolderAudioSlotForResourceType:resourceType]];
    [nleModel addTrack:placeHolderTrack];
}

- (void)p_removePlaceholderMVAudioTrackIfNeeded:(NLEEditor_OC *)nleEditor
                                      videoData:(ACCNLEEditVideoData *)videoData {
    if (nleEditor == nil || videoData == nil) return;
    NLEModel_OC *nleModel = [nleEditor getModel];
    if (nleModel == nil) return;
    
    if (videoData.videoData.audioAssets.count == 0) {
        NLEModel_OC *nleModel = [nleEditor getModel];
        [[nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
            if (obj.isBGMTrack) {
                [nleModel removeTrack:obj];
            }
        }];
    }
}

// 替换BGM类型
- (void)p_updateBGMSubtypeForDraftWithRepository:(AWEVideoPublishViewModel *)repository
                                       videoData:(ACCNLEEditVideoData *)videoData {
    if (repository.repoMV == nil) return;
    if (![videoData isKindOfClass:[ACCNLEEditVideoData class]]) return;
    
    // 设置BGM
    if (repository.repoMusic.bgmAsset) {
        [[videoData.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
            if ([obj.slots.firstObject isRelatedWithAudioAsset:repository.repoMusic.bgmAsset]) {
                obj.isBGMTrack = YES;
            }
        }];
    }
    
    // 设置audioSubType[bgmAsset可能存在和slot不一致的folder，需要单独对加了BGM标识进行处理]
    ACCMVAudioType mvAudioType = [self p_audioTypeInMV:repository];
    [[videoData.nleModel tracksWithType:NLETrackAUDIO] acc_forEach:^(NLETrack_OC * _Nonnull obj) {
        if (obj.isBGMTrack) {
            NLEResourceType resourceType = NLEResourceTypeNormalMVAudio;
            if (mvAudioType == ACCMVAudioTypeAudioBeatTracking) {
                resourceType = NLEResourceTypeAlgorithmMVAudio;
            } else if (mvAudioType == ACCMVAudioTypeEffectMusic) {
                resourceType = NLEResourceTypeMusicMVAudio;
            }
            [obj updateAudioSubType:resourceType];
        }
    }];
}

#pragma mark - Properties

- (IESMMMVModel *)veMVModel
{
    if (!_veMVModel) {
        _veMVModel = [[IESMMMVModel alloc] init];
    }
    return _veMVModel;
}

- (NLETrackMV_OC *)mvTrack
{
    if (!_mvTrack) {
        _mvTrack = [[NLETrackMV_OC alloc] init];
        _mvTrack.smartMovieVideoMode = ACCSmartMovieSceneModeMVVideo;
        _mvTrack.mainTrack = YES;
    }
    return _mvTrack;
}

#pragma mark - 音乐类型

+ (BOOL)p_isEffectMusicMV:(AWEVideoPublishViewModel *)repository {
    BOOL isClassicalMV = repository.repoCutSame.isClassicalMV; // 经典影集
    BOOL isFromShootEntranceMV = AWEVideoTypePhotoToVideo == repository.repoContext.videoType; // 点+进行拍摄之后的MV
    BOOL hasConfigEffectMusic = AWEMVTemplateTypeMusicEffect == repository.repoMV.mvTemplateType; // 模型配置了动效音乐
    
    return hasConfigEffectMusic && (isClassicalMV || isFromShootEntranceMV);
}

- (ACCMVAudioType)p_audioTypeInMV:(AWEVideoPublishViewModel *)repository {
    if ([ACCEditMVModel p_isEffectMusicMV:repository]) return ACCMVAudioTypeEffectMusic;
    if (self.algorithmTrack) return ACCMVAudioTypeAudioBeatTracking;
    return ACCMVAudioTypeNormal;
}

#pragma mark - 获取用户导入的视频片段

+ (NSArray<AVAsset *> *)videoAssetsSelectedByUserFromVideoData:(HTSVideoData *)videoData {
    NSArray<AVAsset *> *videoAssets = videoData.videoAssets;
    if (videoData.mvModel && videoAssets.count > 0) {
        NSMutableArray *tempArr = [videoAssets mutableCopy];
        NSArray<IESMMMVResource *> *resources = videoData.mvModel.resources;
        for (AVAsset *videoAsset in videoAssets) {
            if ([videoAsset isKindOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)videoAsset;
                NSString *assetPath = [urlAsset URL].path;
                if (assetPath.length == 0) continue;
                
                BOOL isUserSelected = NO;
                for (IESMMMVResource *resource in resources) {
                    NSString *resourcePath = resource.resourceContent;
                    if ([assetPath containsString:resourcePath]) {
                        isUserSelected = YES;
                        continue;
                    }
                }
                
                if (!isUserSelected) {
                    [tempArr removeObject:videoAsset];
                }
            }

        }
        
        videoAssets = [tempArr copy];
    }
    return videoAssets;
}

@end
