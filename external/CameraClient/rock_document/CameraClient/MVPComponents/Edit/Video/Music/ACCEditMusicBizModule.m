//
//  ACCEditMusicBizModule.m
//  Indexer
//
//  Created by tangxiaoxi on 2021/10/13.
//

#import "ACCEditMusicBizModule.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "AWERepoVideoInfoModel.h"
#import "ACCRepoCanvasBusinessModel.h"
#import "AWERepoContextModel.h"
#import <IESInject/IESInjectDefines.h>
#import <CreativeKit/ACCBusinessConfiguration.h>
#import "ACCEditorMusicConfigAssembler.h"
#import "AWERepoMusicModel.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CameraClient/ACCVideoMusicProtocol.h>
#import <CameraClient/ACCVideoMusicListResponse.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import "ACCFriendsServiceProtocol.h"
#import <CameraClient/ACCConfigKeyDefines.h>

@interface ACCEditMusicBizModule ()

@property (nonatomic, weak) id<IESServiceProvider> serviceProvider;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<ACCBusinessInputData> inputData;

@end

@implementation ACCEditMusicBizModule
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, inputData, ACCBusinessInputData)

+ (void)fetchMusicModelWithMusicConfig:(ACCMusicConfig * _Nullable)config completion:(void (^ _Nullable)(id<ACCMusicModelProtocol> _Nullable model, NSError *error))completion
{
    if (config.strategy == ACCMusicConfigStrategyHot) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestWithMusicClassId:nil
                                                                                              cursor:nil
                                                                                               count:@(1)
                                                                                         noDuplicate:@(YES)
                                                                                         otherParams:nil
                                                                                          completion:^(ACCVideoMusicListResponse *_Nullable response, NSError * _Nullable error) {
            id<ACCMusicModelProtocol> music = response.musicList.firstObject;
            ACCBLOCK_INVOKE(completion,music,error);
        }];
    } else {
        if (config.music.playURL.URLList.count > 0) {
            ACCBLOCK_INVOKE(completion,config.music,nil);
        } else if (!ACC_isEmptyString(config.musicId)) {
            [ACCVideoMusic() requestMusicItemWithID:config.musicId completion:^(id<ACCMusicModelProtocol>  _Nonnull music, NSError * _Nonnull error) {
                ACCBLOCK_INVOKE(completion,music,nil);
            }];
        } else {
            ACCBLOCK_INVOKE(completion,nil,nil);
        }
    }
}

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>)serviceProvider
{
    self = [super init];
    if (self) {
        _serviceProvider = serviceProvider;
    }
    return self;
}

- (void)setup
{
    if (self.repository.repoMusic.musicConfigAssembler.config.music) {
        self.repository.repoMusic.music = self.repository.repoMusic.musicConfigAssembler.config.music;
    }
}

- (void)fetchMusicModelWithCompletion:(void (^)(id<ACCMusicModelProtocol> _Nullable model, NSError *error))completion
{
    if (self.repository.repoMusic.music) {
        ACCBLOCK_INVOKE(completion,self.repository.repoMusic.music,nil);
    } else {
        [ACCEditMusicBizModule fetchMusicModelWithMusicConfig:self.repository.repoMusic.musicConfigAssembler.config completion:completion];
    }
}

- (void)downloadMusicIfneedWithCompletion:(void (^ _Nullable)(id<ACCMusicModelProtocol> _Nullable model, NSError *error))completion
{
    [self fetchMusicModelWithCompletion:^(id<ACCMusicModelProtocol>  _Nullable model, NSError *error) {
        if (model == nil) {
            ACCBLOCK_INVOKE(completion,model,error);
        } else if (!ACC_isEmptyString(model.loaclAssetUrl.path) &&
            [[NSFileManager defaultManager] fileExistsAtPath:model.loaclAssetUrl.path]) {
            ACCBLOCK_INVOKE(completion,model,error);
        } else {
            [ACCVideoMusic() fetchLocalURLForMusic:model
                                      withProgress:nil
                                        completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
                model.localURL = localURL;
                ACCBLOCK_INVOKE(completion,model,error);
            }];
        }
    }];
}

//move from ACCVideoEditMusicViewModel to support silent publish
- (void)replaceAudio:(NSURL * _Nullable)url completeBlock:(void (^ _Nullable)(void))completeBlock
{
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
            [self.editService.preview play]; //fix me, 确认静默发布时是否需要去掉
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
            [self.editService.preview play]; //fix me, 确认静默发布时是否需要去掉
            ACCBLOCK_INVOKE(completeBlock);
        }];
    }
}

- (AWEVideoPublishViewModel *)repository
{
    return self.inputData.publishModel;
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return self.editService.audioEffect;
}

@end
