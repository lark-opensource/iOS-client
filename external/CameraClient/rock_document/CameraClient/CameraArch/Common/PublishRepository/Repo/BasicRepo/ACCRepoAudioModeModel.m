//
//  ACCRepoAudioModeModel.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/29.
//

#import "ACCRepoAudioModeModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/ACCMacros.h>
#import "AWERepoPublishConfigModel.h"
#import "AWEAudioModeDataHelper.h"
#import "AWERepoVideoInfoModel.h"

@interface AWEVideoPublishViewModel (RepoAudioMode) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoAudioMode)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoAudioModeModel.class];
    return info;
}

- (ACCRepoAudioModeModel *)repoAudioMode
{
    ACCRepoAudioModeModel *audioModeModel = [self extensionModelOfClass:ACCRepoAudioModeModel.class];
    NSAssert(audioModeModel, @"extension model should not be nil");
    return audioModeModel;
}

@end

@implementation ACCRepoAudioModeModel

@synthesize repository;

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoAudioModeModel *model = [[[self class] alloc] init];
    model.isAudioMode = self.isAudioMode;
    model.mvModel = self.mvModel;
    model.audioMvId = self.audioMvId;
    model.materialPaths = self.materialPaths;
    model.bgaudioAssetPath = self.bgaudioAssetPath;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *mutableParameter = @{}.mutableCopy;
    return mutableParameter.copy;
}

- (void)generateMVFromDraftVideoData:(ACCEditVideoData *)videoData
                              taskId:(NSString *)taskId
                          completion:(void(^)(ACCEditVideoData *, NSError *))completion
{
    if (ACC_isEmptyArray(self.materialPaths)) {
        NSError *resourceError = [NSError errorWithDomain:@"aweme.creative.audioMode" code:-2 userInfo:@{@"msg": @"resource images losed"}];
        ACCBLOCK_INVOKE(completion, nil, resourceError);
    } else {
        @weakify(self);
        [AWEAudioModeDataHelper prefetchAudioMVTemplate:^(BOOL success, IESEffectModel *templateModel) {
            @strongify(self);
//            [self recoverAudioAsset:videoData]; 草稿迁移的恢复videoData存在异常 不支持草稿迁移先注释 同K歌，VE字段对齐后可开启
            self.mvModel = [AWEAudioModeDataHelper generateAudioMVDataWithImages:self.materialPaths
                                                                   templateModel:templateModel
                                                                      repository:(AWEVideoPublishViewModel *)self.repository
                                                                     draftFolder:self.draftFolder
                                                                       videoData:videoData
                                                                      completion:^(ACCEditVideoData *resultVideoData, NSError *error) {
                if (resultVideoData && !error) {
                    ACCBLOCK_INVOKE(completion, resultVideoData, nil);
                } else {
                    ACCBLOCK_INVOKE(completion, nil, error);
                }
            }];
        }];
    }
}

- (NSString *)draftFolder
{
    ACCRepoDraftModel *draftModel = [self.repository extensionModelOfClass:[ACCRepoDraftModel class]];
    return draftModel.draftFolder;
}

- (void)recoverAudioAsset:(ACCEditVideoData *)videoData
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.bgaudioAssetPath]) {
        NSURL *url = [NSURL fileURLWithPath:self.bgaudioAssetPath];
        AVAsset *bgAudioAsset = [AVURLAsset URLAssetWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        if (!bgAudioAsset) {
            return;
        }
        videoData.bgAudioAssets = @[bgAudioAsset];
        AWERepoVideoInfoModel *videoInfoModel = [self.repository extensionModelOfClass:[AWERepoVideoInfoModel class]];
        [videoInfoModel updateVideoData:videoData];
    }
}

@end
