//
//  ACCEditCanvasLivePhotoUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/15.
//

#import "ACCEditCanvasLivePhotoUtils.h"
#import <TTVideoEditor/IESMMCanvasConfig.h>
#import <TTVideoEditor/IESMMCanvasSource.h>
#import <TTVideoEditor/IESMMBlankResource.h>
#import <TTVideoEditor/IESMMParamModule.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/ACCMacros.h>

#import "ACCEditCanvasConfigProtocol.h"
#import "ACCEditVideoData.h"
#import "ACCRepoLivePhotoModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "AWERepoDraftModel.h"


@implementation ACCEditCanvasLivePhotoUtils

+ (void)configLivePhotoWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    BOOL handled = NO;
    let bizType = publishModel.repoLivePhoto.businessType;
    switch (bizType) {
        case ACCLivePhotoTypeNone:
            NSAssert(NO, @"invalid case");
            break;
        case ACCLivePhotoTypeBoomerang:
            handled = YES;
            [self p_configBoomerangWithPublishModel:publishModel];
            break;
        case ACCLivePhotoTypePlainRepeat:
            handled = YES;
            [self p_configPlainRepeatWithPublishModel:publishModel];
            break;
    }
    // 兜底逻辑
    if (!handled) {
        [self p_configBoomerangWithPublishModel:publishModel];
    }
}

+ (void)p_configBoomerangWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    CGFloat totalSeconds = 0;
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:publishModel.repoDraft.taskID];
    let repeat = publishModel.repoLivePhoto.repeatCount;

    for (NSInteger repeatCount = 0; repeatCount < repeat; ++repeatCount) {
        for (NSString *filePath in publishModel.repoLivePhoto.imagePathList) {
            [self addFrameToVideoWithPublishModel:publishModel withFilePath:[draftFolder stringByAppendingPathComponent:filePath] attachSeconds:totalSeconds];
            totalSeconds += [self durationPerFrame:publishModel.repoLivePhoto.durationPerFrame];
        }
        for (NSString *filePath in [publishModel.repoLivePhoto.imagePathList reverseObjectEnumerator]) {
            [self addFrameToVideoWithPublishModel:publishModel withFilePath:[draftFolder stringByAppendingPathComponent:filePath] attachSeconds:totalSeconds];
            totalSeconds += [self durationPerFrame:publishModel.repoLivePhoto.durationPerFrame];
        }
    }
    publishModel.repoContext.maxDuration = totalSeconds;
}

+ (void)p_configPlainRepeatWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    CGFloat totalSeconds = 0;
    NSString *draftFolder = [AWEDraftUtils generateDraftFolderFromTaskId:publishModel.repoDraft.taskID];
    let repeat = publishModel.repoLivePhoto.repeatCount;
    
    for (NSInteger repeatCount = 0; repeatCount < repeat; ++repeatCount) {
        for (NSString *filePath in publishModel.repoLivePhoto.imagePathList) {
            [self addFrameToVideoWithPublishModel:publishModel withFilePath:[draftFolder stringByAppendingPathComponent:filePath] attachSeconds:totalSeconds];
            totalSeconds += [self durationPerFrame:publishModel.repoLivePhoto.durationPerFrame];
        }
    }
    publishModel.repoContext.maxDuration = totalSeconds;
}

+ (CGFloat)durationPerFrame:(CGFloat)originValue
{
    // 最高支持 40fps，即 0.025 = 1.0 / 40
    return MAX(0.025, originValue);
}

+ (void)addFrameToVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel withFilePath:(NSString *)filePath attachSeconds:(CGFloat)attachSeconds
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    BOOL veab = [[IESMMParamModule sharedInstance] veabtest_massive_import_optimization];
    AVAsset *placeholderAsset = veab ? [IESMMBlankResource getEmptyAVAsset] : [IESMMBlankResource getBlackVideoAsset];
    [videoData addVideoWithAsset:placeholderAsset];
    [videoData updatePhotoAssetInfoWithURL:[NSURL fileURLWithPath:filePath] asset:placeholderAsset];
    
    [videoData updateVideoTimeClipInfoWithClipRange:IESMMVideoDataClipRangeMakeV2(0, [self durationPerFrame:publishModel.repoLivePhoto.durationPerFrame], attachSeconds, 1) asset:placeholderAsset];

    id<ACCEditCanvasConfigProtocol> canvasConfig = IESAutoInline(ACCBaseServiceProvider(), ACCEditCanvasConfigProtocol);
    IESMMCanvasConfig *config = [canvasConfig configWithPublishModel:publishModel];
    if (config != nil) {
        [videoData updateCanvasConfigsMapWithConfig:config asset:placeholderAsset];
    }

    if (videoData.preferCanvasConfig == nil) {
        videoData.preferCanvasConfig = config;
    }

    IESMMCanvasSource *source = [canvasConfig sourceWithPublishModel:publishModel mediaContainerView:nil]; // internal coupling with no necessary, so nil here is OK, after refactor in ACCEditCanvasConfigProtocol implemetation, the interface will no longer need param mediaContainerView
    if (source != nil) {
        [videoData updateCanvasInfoWithCanvasSource:source asset:placeholderAsset];
    }
}

@end
