//
//  AWEAudioModeDataHelper.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/4.
//

#import "AWEAudioModeDataHelper.h"
#import <CameraClient/ACCEditMVModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CameraClient/AWEMVTemplateModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCRepoAudioModeModel.h"

static NSString *const kAWEAudioMVTemplatePanelName = @"voice_publish";

@interface AWEAudioModeDataHelper()

@property (nonatomic, assign) BOOL isTemplateDownloading;

@end

@implementation AWEAudioModeDataHelper

+ (void)prefetchAudioMVTemplate:(void(^)(BOOL success, IESEffectModel *templateModel))completion
{
    [AWEEffectPlatformManager configEffectPlatform];
    [EffectPlatform checkEffectUpdateWithPanel:kAWEAudioMVTemplatePanelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:kAWEAudioMVTemplatePanelName];
        if (needUpdate || cachedResponse.effects.count <= 0) {
            [EffectPlatform downloadEffectListWithPanel:kAWEAudioMVTemplatePanelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                if (!error && response.effects.count > 0) {
                    IESEffectModel *model = response.effects.firstObject;
                    [[AWEMVTemplateModel sharedManager] downloadMaterialWithEffect:model completion:^(IESEffectModel * _Nullable mvEffectModel) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ACCBLOCK_INVOKE(completion, YES, model);
                        });
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ACCBLOCK_INVOKE(completion, NO, nil);
                    });
                }
            }];
        } else {
            if (cachedResponse.effects.count > 0) {
                IESEffectModel *model = cachedResponse.effects.firstObject;
                if (model.downloaded) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        ACCBLOCK_INVOKE(completion, YES, model);
                    });
                } else {
                    [[AWEMVTemplateModel sharedManager] downloadMaterialWithEffect:model completion:^(IESEffectModel * _Nullable mvEffectModel) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            ACCBLOCK_INVOKE(completion, YES, model);
                        });
                    }];
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    ACCBLOCK_INVOKE(completion, NO, nil);
                });
            }
        }
    }];
}

+ (ACCEditMVModel *)generateAudioMVDataWithImages:(NSArray *)images
                                    templateModel:(IESEffectModel *)model
                                       repository:(AWEVideoPublishViewModel *)repository
                                      draftFolder:(NSString *)draftFolder
                                        videoData:(ACCEditVideoData *)videoData
                                       completion:(void(^)(ACCEditVideoData *result, NSError *error))completion
{
    if (!model.downloaded) {
        NSError *templateNotReadyError = [NSError errorWithDomain:@"aweme.creative.audioMode" code:-1 userInfo:@{@"msg": @"audio mv template is not downloaded"}];
        ACCBLOCK_INVOKE(completion, nil, templateNotReadyError);
        return nil;
    }
    NSString *mvPath = model.filePath;
    ACCEditMVModel *mvModel = [[ACCEditMVModel alloc] initWithDraftFolder:draftFolder];
    CGSize resolutionSize = ACCConfigBool(kConfigBool_enable_1080p_mv_video) ? CGSizeMake(1080, 1920) : CGSizeMake(720, 1280);
    [mvModel setResolution:resolutionSize];
    [mvModel setVariableDuration:videoData.totalBGAudioDuration];
    //传入头像和图片
    NSMutableArray *resources = [[NSMutableArray alloc] init];
    [images enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESMMMVResource *resource = [[IESMMMVResource alloc] init];
        resource.resourceContent = obj;
        resource.resourceType = IESMMMVResourcesType_img;
        [resources acc_addObject:resource];
    }];
    [mvModel generateMVWithPath:mvPath repository:repository userResourses:[resources copy] videoData:[videoData copy] completion:^(BOOL result, NSError *error, ACCEditVideoData *info) {
        repository.repoAudioMode.audioMvId = model.effectIdentifier;
        repository.repoAudioMode.materialPaths = images;
//        暂不支持草稿迁移videoData恢复存在异常 VE字段对齐后可开启
//        if (!ACC_isEmptyArray(info.bgAudioAssets)) {
//            repository.repoAudioMode.bgaudioAssetPath = [AWEAudioModeDataHelper outputBgAudioAsset:info.bgAudioAssets.firstObject withDraftID:repository.repoDraft.taskID];
//        }
        acc_dispatch_main_async_safe(^{
            if (result && !error && info) {
                ACCBLOCK_INVOKE(completion, info, nil);
            } else {
                ACCBLOCK_INVOKE(completion, nil, error);
            }
        });
    }];
    return mvModel;
}

+ (NSString *)outputBgAudioAsset:(AVAsset *)asset withDraftID:(NSString *)taskID
{
    NSString *folderPath = [AWEDraftUtils generateDraftFolderFromTaskId:taskID];
    AVURLAsset *urlAsset = (AVURLAsset *)asset;
    NSError *error = nil;
    NSString *filePath = [folderPath stringByAppendingString:[NSString stringWithFormat:@"/%@audioAsset.mov", taskID]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:urlAsset.URL.path]) {
        [[NSFileManager defaultManager] copyItemAtPath:urlAsset.URL.path toPath:filePath error:&error];
    }
    if (error) {
        return nil;
    } else {
        return filePath;
    }
}

@end
