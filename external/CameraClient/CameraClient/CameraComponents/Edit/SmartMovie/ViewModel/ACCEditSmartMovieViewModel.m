//
//  ACCEditSmartMovieViewModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/2.
//

#import "ACCEditSmartMovieViewModel.h"
#import "ACCMVTemplateManagerProtocol.h"

#import <IESInject/IESInject.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#import <CameraClient/ACCEditMVModel.h>
#import <CameraClient/AWERepoMVModel.h>
#import <CameraClient/AWEMVTemplateModel.h>
#import <CameraClient/ACCSmartMovieUtils.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCNLEEditVideoData.h>
#import <CameraClient/AWERepoVideoInfoModel.h>

#import <CameraClient/NLEModel_OC+Extension.h>
#import <CameraClient/NLETrack_OC+Extension.h>
#import <CameraClient/NLEEditor_OC+Extension.h>
#import <CameraClient/ACCEditVideoDataFactory.h>
#import <CameraClient/AWERepoTranscodingModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCEditVideoDataDowngrading.h>
#import <CameraClient/ACCSmartMovieManagerProtocol.h>
#import <CameraClient/AWEVideoRecordOutputParameter.h>
#import <CreationKitInfra/ACCConfigManager.h>

#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>

#import <NLEPlatform/NLEInterface.h>

@interface ACCEditSmartMovieViewModel ()

@property (nonatomic, strong) id<ACCMVTemplateManagerProtocol> mvTemplateManager;
@property (nonatomic, weak) id<ACCSmartMovieManagerProtocol> smartMovieManager;

/** 以下数据用于音乐切换时候数据恢复 */
@property (nonatomic, assign) BOOL existsBackup;
@property (nonatomic, strong, nullable) ACCNLEEditVideoData *videoBackup; // video备份数据
@property (nonatomic, strong, nullable) ACCEditMVModel *mmmvModelBackup; // AACCEditMVModel备份数据
@property (nonatomic, strong, nullable) id<ACCMusicModelProtocol> musicBackup; // music备份数据

@end

@implementation ACCEditSmartMovieViewModel

- (void)exportDataForMode:(ACCSmartMovieSceneMode)mode
               repository:(AWEVideoPublishViewModel *_Nonnull)repository
                  musicID:(NSString *_Nullable)musicID
                  succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                   failed:(void(^_Nullable)(void))failedBlock
{
    switch (mode) {
        case ACCSmartMovieSceneModeMVVideo: {
            [self exportMVVideoWithRepository:repository
                                      succeed:succeedBlock
                                       failed:failedBlock];
            break;
        }
            
        case ACCSmartMovieSceneModeSmartMovie: {
            [self exportSmartMovieWithRepository:repository
                                         musicID:musicID
                                         succeed:succeedBlock
                                          failed:failedBlock];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Private Methods

- (void)exportMVVideoWithRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                            succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                             failed:(void(^_Nullable)(void))failedBlock
{
    @weakify(self);
    self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
    self.mvTemplateManager.publishModel = repository;

    self.mvTemplateManager.customerTransferHandler = ^(BOOL isCanceled, AWEVideoPublishViewModel *_Nullable result) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager.customerTransferHandler = nil;
            self.mvTemplateManager = nil;
            ACCBLOCK_INVOKE(succeedBlock, result, NO);
        });
    };
    
    [self.mvTemplateManager exportMVVideoWithAssetModels:repository.repoUploadInfo.selectedUploadAssets
                                            needsLoading:NO
                                             failedBlock:^{
        @strongify(self);
        self.mvTemplateManager = nil;
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager.customerTransferHandler = nil;
            self.mvTemplateManager = nil;
            ACCBLOCK_INVOKE(failedBlock);
        });
    } successBlock:^{
        // 在customerTransferHandler中处理了
    }];
}

- (void)exportSmartMovieWithRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                               musicID:(NSString *_Nullable)musicID
                               succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                                failed:(void(^_Nullable)(void))failedBlock
{
    if ([self.smartMovieManager isCanceled]) {
        ACCBLOCK_INVOKE(succeedBlock, repository, YES);
        return;
    }
    @weakify(self);
    self.mvTemplateManager = IESAutoInline(ACCBaseServiceProvider(), ACCMVTemplateManagerProtocol);
    self.mvTemplateManager.publishModel = repository;

    self.mvTemplateManager.customerTransferHandler = ^(BOOL isCanceled, AWEVideoPublishViewModel *_Nullable result) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager = nil;
            self.mvTemplateManager.customerTransferHandler = nil;
            ACCBLOCK_INVOKE(succeedBlock, result, isCanceled);
        });
    };
    
    [self.mvTemplateManager exportSmartMovieWithAssetModels:repository.repoUploadInfo.selectedUploadAssets
                                                    musicID:musicID
                                               needsLoading:NO
                                                failedBlock:^{
        @strongify(self);
        self.mvTemplateManager = nil;
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            self.mvTemplateManager = nil;
            self.mvTemplateManager.customerTransferHandler = nil;
            ACCBLOCK_INVOKE(failedBlock);
        });
    } successBlock:^{
        // 在customerTransferHandler中处理了
    }];
}

- (void)refreshRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                  musicID:(NSString *_Nonnull)musicID
                  succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                   failed:(void(^_Nullable)(void))failedBlock
{
    if ([self.smartMovieManager isCanceled]) {
        ACCBLOCK_INVOKE(succeedBlock, repository, YES);
        return;
    }
    
    self.existsBackup = YES;
    // 草稿恢复可能没有这个model，需要重新构建一个
    ACCEditMVModel *mmmvModel = repository.repoMV.mvModel;
    self.mmmvModelBackup = mmmvModel;
    if (!mmmvModel) {
        mmmvModel = [[ACCEditMVModel alloc] initWithDraftFolder:repository.repoDraft.draftFolder];
        CGSize resolutionSize = ACCConfigBool(kConfigBool_enable_1080p_photo_to_video) ? CGSizeMake(1080, 1920) : CGSizeMake(720, 1280);
        [mmmvModel setResolution:resolutionSize];
        repository.repoMV.mvModel = mmmvModel;
    }

    if (!repository.repoMusic.music) {
        id<ACCMusicModelProtocol> musicModel = [[AWEMVTemplateModel sharedManager] videoMusicModelWithType:repository.repoContext.photoToVideoPhotoCountType];
        repository.repoMusic.music = musicModel;
        // 不设置bgmAsset，会被外部pannel把音量置0
        repository.repoMusic.bgmAsset = [AVAsset assetWithURL:musicModel.loaclAssetUrl];
    }
    
    if ([self.smartMovieManager isCanceled]) {
        self.videoBackup = nil;
        ACCBLOCK_INVOKE(succeedBlock, repository, YES);
        return;
    }
    // 备份数据
    self.videoBackup = (ACCNLEEditVideoData *)repository.repoVideoInfo.video;
    // 生成 SmartMovie
    @weakify(self);
    NSArray<NSString *> *assets = repository.repoSmartMovie.assetPaths;
    [mmmvModel generateSmartMovieWithRepository:repository
                                         assets:assets
                                        musicID:musicID
                                  isSwitchMusic:(musicID ? YES : NO)
                                     completion:^(BOOL isCanceled,
                                                  ACCEditVideoData *info,
                                                  NSError *error, BOOL isNleRenderError) {
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            if (isCanceled) {
                ACCBLOCK_INVOKE(succeedBlock, repository, YES);
            } else if (info) {
                [self updateRepository:repository withVideoData:(ACCNLEEditVideoData *)info];
                ACCBLOCK_INVOKE(succeedBlock, repository, NO);
            } else {
                [self recoveryRepository:repository];
                ACCBLOCK_INVOKE(failedBlock);
            }
        });
    }];
}

#pragma mark - Backup Methods

- (void)recoveryRepository:(AWEVideoPublishViewModel *_Nonnull)repository
{
    if (self.existsBackup) {
        repository.repoMV.mvModel = self.mmmvModelBackup;
        repository.repoMusic.music = self.musicBackup;
        [self updateRepository:repository withVideoData:self.videoBackup];
        [self clearBackups];
    }
}

- (void)backupMusic:(id<ACCMusicModelProtocol> _Nullable)music
{
    self.musicBackup = music;
    self.existsBackup = YES;
}

- (void)clearBackups
{
    self.mmmvModelBackup = nil;
    self.videoBackup = nil;
    self.musicBackup = nil;
    self.existsBackup = NO;
}

#pragma mark - Private Methods

- (void)updateRepository:(AWEVideoPublishViewModel *)repository withVideoData:(ACCNLEEditVideoData *)videoData
{
    if (!videoData || ![videoData isKindOfClass:ACCNLEEditVideoData.class]) {
        return;
    }
    [repository.repoVideoInfo updateVideoData:videoData];
    [self updateRepositoryVideoSize:repository];
    
    if (repository.repoMusic.bgmAsset) {
        [repository.repoMV.mvModel clearAndAddBGMWithVideoData:videoData
                                                      bgmAsset:repository.repoMusic.bgmAsset
                                                    repository:repository];
    }
}

- (void)updateRepositoryVideoSize:(AWEVideoPublishViewModel *)repository
{
    ACCEditVideoData *videoData = repository.repoVideoInfo.video;
    // Draft restoration using MV template composition resolution
    CGSize mvTemplateSize = videoData.transParam.videoSize;
    // todo: bitrate
    if (!CGSizeEqualToSize(mvTemplateSize, CGSizeZero)) {
        repository.repoTranscoding.outputWidth = mvTemplateSize.width;
        repository.repoTranscoding.outputHeight = mvTemplateSize.height;;
    } else {
        CGSize exportSize = [AWEVideoRecordOutputParameter maximumImportExportSize];
        repository.repoTranscoding.outputWidth = exportSize.width;
        repository.repoTranscoding.outputHeight = exportSize.height;
        videoData.transParam.videoSize = exportSize;
    }
}

#pragma mark - Getter
- (id<ACCSmartMovieManagerProtocol>)smartMovieManager
{
    if (!_smartMovieManager) {
        _smartMovieManager = acc_sharedSmartMovieManager();
    }
    return _smartMovieManager;
}

- (void)setVideoBackup:(ACCNLEEditVideoData *)videoBackup
{
    if ([videoBackup isKindOfClass:ACCNLEEditVideoData.class]) {
        _videoBackup = videoBackup;
    } else {
        _videoBackup = nil;
    }
}

@end
