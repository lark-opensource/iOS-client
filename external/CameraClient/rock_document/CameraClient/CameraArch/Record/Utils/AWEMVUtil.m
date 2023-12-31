//
//  AWEMVUtil.m
//  Pods
//
//  Created by zhangchengtao on 2019/4/17.
//

#import "AWEMVUtil.h"

#import <CameraClient/ACCMusicNetServiceProtocol.h>

#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import "AWERepoMVModel.h"

@implementation AWEMVUtil

+ (BOOL)precheckShouldCreateMVPlayerWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    NSParameterAssert(publishViewModel);
    if (!publishViewModel) {
        return NO;
    }

    BOOL isMV = publishViewModel.repoContext.isMVVideo || AWEVideoTypePhotoToVideo == publishViewModel.repoContext.videoType;
    NSParameterAssert(isMV);
    if (!isMV) {
        return NO;
    }

    if (!publishViewModel.repoMV.mvModel) {
        return NO;
    }

    return YES;
}

+ (void)preprocessPublishViewModelForMVPlayer:(AWEVideoPublishViewModel *)publishViewModel
{
    if (publishViewModel.repoMV.templateMusicId.length > 0 && nil == publishViewModel.repoMV.mvMusic) {
        NSURL *musicURL;
        if (publishViewModel.repoMV.templateMusicFileName.length > 0) {
            NSString *musicPath = [[publishViewModel.repoDraft draftFolder] stringByAppendingPathComponent:publishViewModel.repoMV.templateMusicFileName];
            if ([[NSFileManager defaultManager] fileExistsAtPath:musicPath]) {
                musicURL = [NSURL fileURLWithPath:musicPath];
                id<ACCMusicModelProtocol> mvMusicModel = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createMusicModel];
                mvMusicModel.musicID = publishViewModel.repoMV.templateMusicId;
                mvMusicModel.loaclAssetUrl = musicURL;
                publishViewModel.repoMV.mvMusic = mvMusicModel;
            }
        }

        id<ACCMusicModelProtocol> mvMusic;
        NSString *mvCacheKey;
        if ([publishViewModel.repoMV.templateMusicId length]) {
            mvCacheKey = [NSString stringWithFormat:@"%@_%@",ACCMVMusicCacheKeyPrefix,publishViewModel.repoMV.templateMusicId];
            mvMusic = [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) fetchCachedMusicWithID:nil cacheKey:mvCacheKey];
            if (mvMusic) {
                publishViewModel.repoMV.mvMusic = mvMusic;
                if([musicURL.absoluteString length]) {
                    mvMusic.loaclAssetUrl = musicURL;
                }
            }
        }

        if (!mvMusic) {

            [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:publishViewModel.repoMV.templateMusicId completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
                if (model) {
                    publishViewModel.repoMV.mvMusic = model;
                    if([musicURL.absoluteString length]) {
                       publishViewModel.repoMV.mvMusic.loaclAssetUrl = musicURL;
                    }
                    if (mvCacheKey) {
                       [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) cacheMusicModel:model cacheKey:mvCacheKey];
                    }
                }
                
                if (error) {
                    AWELogToolError(AWELogToolTagMusic, @"requestMusicItemWithID: %@", error);
                }
            }];
        }
    }
}

+ (BOOL)shouldConfigPlayerWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    return [self precheckShouldCreateMVPlayerWithPublishViewModel:publishViewModel];
}

@end
