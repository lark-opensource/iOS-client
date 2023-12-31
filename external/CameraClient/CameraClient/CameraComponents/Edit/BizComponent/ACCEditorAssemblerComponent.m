//
//  ACCEditorAssemblerComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/9/18.
//

#import "ACCEditorAssemblerComponent.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <IESInject/IESInjectDefines.h>
#import <CreativeKit/ACCMacros.h>

#import "AWERepoMusicModel.h"
#import "AWERepoContextModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoUploadInfomationModel.h"
#import "AWEVideoEffectPathBlockManager.h"

#import "ACCEditorStickerComponent.h"
#import "ACCEditorVolumeComponent.h"
#import "ACCEditorMusicComponent.h"
#import <CreationKitInfra/ACCLogHelper.h>

@interface ACCEditorAssemblerComponent ()

@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) ACCEditorStickerComponent *stickerComponent; // design for register later
@property (nonatomic, strong) ACCEditorVolumeComponent *volumeComponent; // design for register later
@property (nonatomic, strong) ACCEditorMusicComponent *musicComponent; // design for register later

@end

@implementation ACCEditorAssemblerComponent
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider, IESServiceRegister>) serviceProvider
{
    self = [super initWithServiceProvider:serviceProvider];
    if (self) {
        _stickerComponent = [[ACCEditorStickerComponent alloc] initWithServiceProvider:serviceProvider];
        _volumeComponent = [[ACCEditorVolumeComponent alloc] initWithServiceProvider:serviceProvider];
        _musicComponent = [[ACCEditorMusicComponent alloc] initWithServiceProvider:serviceProvider];
    }
    return self;
}

- (void)setRepository:(AWEVideoPublishViewModel *)repository
{
    [super setRepository:repository];
    self.stickerComponent.repository = repository;
    self.volumeComponent.repository = repository;
    self.musicComponent.repository = repository;
}

- (void)configEnvironment
{
    [[self editService].effect setEffectPathBlock:[AWEVideoEffectPathBlockManager pathConvertBlock:self.repository]];
    [[self editService] resetPlayerAndPreviewEdge];
    self.repository.repoMusic.isLVAudioFrameModel = YES;
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
        [self editService].audioEffect.bgmAsset = self.repository.repoMusic.bgmAsset;
    }
    if ([self.repository.repoVideoInfo isMultiVideoFastImport] && self.repository.repoUploadInfo.videoClipMode == AWEVideoClipModeAI) {
        self.repository.repoMusic.voiceVolume = 0;
        [[self editService].audioEffect setVolume:0 forVideoAssets:self.repository.repoVideoInfo.video.videoAssets];
    }
}

- (void)setupWithCompletion:(void (^)(NSError *))completion
{
    [self configEnvironment];
    
    NSArray<ACCEditorComponent *> *componetArray = @[self.stickerComponent,self.volumeComponent,self.musicComponent];
    
    __block NSError *lastError;
    dispatch_group_t group = dispatch_group_create();
    [componetArray enumerateObjectsUsingBlock:^(ACCEditorComponent * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_group_enter(group);
        [obj setupWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                AWELogToolError(AWELogToolTagPublish, @"edit component %@ setup error: %@", NSStringFromClass(obj.class),error);
                lastError = error;
            }
            dispatch_group_leave(group);
        }];
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        ACCBLOCK_INVOKE(completion,lastError);
    });
}

@end
