//
//  ACCCanvasUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/6/10.
//

#import "ACCCanvasUtils.h"
#import "AWEShareMusicToStoryUtils.h"
#import "ACCFriendsServiceProtocol.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoContextModel.h"
#import "ACCRepoQuickStoryModel.h"
#import "AWEVideoRecordOutputParameter.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRepoCanvasModel.h"
#import "ACCEditCanvasConfigProtocol.h"
#import "AWEAssetModel.h"
#import "ACCRepoLivePhotoModel.h"
#import "ACCEditCanvasLivePhotoUtils.h"
#import <TTVideoEditor/IESMMBlankResource.h>
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditVideoDataConsumer.h"
#import <TTVideoEditor/AVAsset+Utils.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@implementation ACCCanvasUtils

+ (void)setUpCanvasWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                 mediaContainerView:(UIView *)mediaContainerView
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    videoData.crossplatInput = YES;
    videoData.crossplatCompile = YES;
    
    // VideoData is Broken need rebuild
    BOOL isBorkenVideoData = [videoData.videoAssets acc_any:^BOOL(AVAsset * _Nonnull obj) {
        if (![ACCEditVideoDataConsumer isPlaceholderVideoAssets:obj]) {
            return NO;
        }
        return videoData.photoAssetsInfo[obj] == nil;
    }];
    
    // videoData is broken or videoData is never generated
    if (videoData.videoAssets.count == 0 || isBorkenVideoData) {
        [self p_reGenerateCanvasWithPublishModel:publishModel
                              mediaContainerView:mediaContainerView];
    }
    
    if (videoData.videoAssets.count == 1) {
        AVAsset *asset = [videoData.videoAssets firstObject];
        if ([asset isBlankVideo] &&
            [AWEShareMusicToStoryUtils enableShareMusicToStoryClipEntry:publishModel.repoVideoInfo.canvasType]) {
            // 转发音乐到日常，TTVideoEditor 内部存储的 videoAsset 为 IESMMBlankAsset，时长为0，这里替换为与音乐时长相等的占位视频
            AVAsset *originalAsset = [videoData.videoAssets firstObject];
            ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
            AVAsset *placeholderAsset = [self canvasVideoAssetWithPublishModel:publishModel];
            IESMMVideoDataClipRange *range = videoData.videoTimeClipInfo[originalAsset];
            videoData.videoTimeClipInfo = @{};
            [videoData updateVideoTimeClipInfoWithClipRange:range asset:placeholderAsset];

            id<ACCEditCanvasConfigProtocol> canvasConfig = IESAutoInline(ACCBaseServiceProvider(), ACCEditCanvasConfigProtocol);
            IESMMCanvasConfig *config = [canvasConfig configWithPublishModel:publishModel];
            if (config != nil) {
                [videoData updateCanvasConfigsMapWithConfig:config asset:placeholderAsset];
            }

            IESMMCanvasSource *source = [canvasConfig sourceWithPublishModel:publishModel mediaContainerView:mediaContainerView];
            if (source != nil) {
                [videoData updateCanvasInfoWithCanvasSource:source asset:placeholderAsset];
            }
        }
    }
}
    
+ (void)p_reGenerateCanvasWithPublishModel:(AWEVideoPublishViewModel *)publishModel
                        mediaContainerView:(UIView *)mediaContainerView
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    // Reset all canvas data
    videoData.canvasInfo = @{};
    videoData.canvasConfigsMap = @{};
    videoData.photoAssetsInfo = @{};
    videoData.videoTimeClipInfo = @{};
    // ---
    
    CGSize exportSize = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].exportSize;
    if (exportSize.width < 1080) {
        exportSize = CGSizeMake(1080, 1920);
    }
    videoData.transParam.videoSize = exportSize;
    videoData.transParam.targetVideoSize = [AWEVideoRecordOutputParameter currentMaxExportSize];
    videoData.canvasSize = exportSize;
    
    ACCRepoTranscodingModel *transcodingModel = publishModel.repoTranscoding;
    transcodingModel.outputWidth = [AWEVideoRecordOutputParameter currentMaxExportSize].width;
    transcodingModel.outputHeight = [AWEVideoRecordOutputParameter currentMaxEditSize].height;
    
    if (publishModel.repoLivePhoto.businessType != ACCLivePhotoTypeNone) {
        [ACCEditCanvasLivePhotoUtils configLivePhotoWithPublishModel:publishModel];
    } else {
        AVAsset *videoAsset = [self canvasVideoAssetWithPublishModel:publishModel];
        [self setupVideoDurationForVideoAsset:videoAsset publishModel:publishModel];
        
        id<ACCEditCanvasConfigProtocol> canvasConfig = IESAutoInline(ACCBaseServiceProvider(), ACCEditCanvasConfigProtocol);
        IESMMCanvasConfig *config = [canvasConfig configWithPublishModel:publishModel];
        if (config != nil) {
            [videoData updateCanvasConfigsMapWithConfig:config asset:videoAsset];
        }

        IESMMCanvasSource *source = [canvasConfig sourceWithPublishModel:publishModel mediaContainerView:mediaContainerView];
        if (source != nil) {
            [videoData updateCanvasInfoWithCanvasSource:source asset:videoAsset];
        }
    }
}

+ (AVAsset *)canvasVideoAssetWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (publishModel.repoCanvas.canvasContentType == ACCCanvasContentTypeVideo && publishModel.repoCanvas.videoURL != nil) {
        ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:publishModel.repoCanvas.videoURL options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)}];
        [videoData addVideoWithAsset:asset];
        
        return asset;
    }
    return [self canvasVideoWithPhoto:publishModel.repoUploadInfo.toBeUploadedImage publishModel:publishModel];
}

+ (void)setupVideoDurationForVideoAsset:(AVAsset *)videoAsset publishModel:(AWEVideoPublishViewModel *)publishModel
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    ACCSinglePhotoOptimizationABTesting canvasPhotoABSettings = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting];
    NSTimeInterval duration = [publishModel repoCanvas].videoDuration;
    if (publishModel.repoVideoInfo.shouldAccommodateVideoDurationToMusicDuration) {
        duration = MIN(MAX(publishModel.repoMusic.music.duration.doubleValue, canvasPhotoABSettings.minimumVideoDuration), canvasPhotoABSettings.maximumVideoDuration);
    }

    [videoData updateVideoTimeClipInfoWithClipRange:IESMMVideoDataClipRangeMake(0, duration) asset:videoAsset];
    publishModel.repoContext.maxDuration = duration;
}

+ (AVAsset *)canvasVideoWithPhoto:(UIImage *)image publishModel:(AWEVideoPublishViewModel *)publishModel
{
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    __block AVAsset *placeholderAsset = nil;
    if ([AWEShareMusicToStoryUtils enableShareMusicToStoryClipEntry:publishModel.repoVideoInfo.canvasType]) {
        // 构造一个音频长度的占位视频
        CGFloat duration = publishModel.repoMusic.music.duration.floatValue;
        placeholderAsset = [IESMMBlankResource getBlackVideoAssetWithDuration:duration];
        if (placeholderAsset) {
            videoData.videoAssets = @[placeholderAsset];
        }
    } else {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"IESPhoto" ofType:@"bundle"];
        NSString *backVideoPath = [bundlePath stringByAppendingPathComponent:@"blankown2.mp4"];
        placeholderAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:backVideoPath] options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @(YES)}];
        videoData.videoAssets = @[placeholderAsset];
    }
    
    [self updateCanvasContentWithPhoto:image publishModel:publishModel];
    
    return placeholderAsset;
}

+ (void)updateCanvasContentWithPhoto:(UIImage *)image publishModel:(AWEVideoPublishViewModel *)publishModel {
    ACCEditVideoData *videoData = publishModel.repoVideoInfo.video;
    if (videoData.videoAssets.count <= 0) {
        return;
    }
    void(^writeDataBlock)(NSString *) = ^(NSString *taskID){
        if (taskID.length <= 0) {
            return;
        }
        NSData *imageData = UIImagePNGRepresentation(image);
        NSString *imagePath = [AWEDraftUtils generateToBeUploadedImagePathFromTaskId:taskID];
        NSURL *imageURL = [NSURL fileURLWithPath:imagePath];
        [imageData acc_writeToFile:imagePath atomically:YES];
        [videoData updatePhotoAssetInfoWithURL:imageURL asset:videoData.videoAssets.firstObject];
        videoData.videoAssets.firstObject.frameImageURL = imageURL;

        if (ACCConfigBool(kConfigBool_single_photo_upload_optimization)) {
            // 改为异步存储后之前videodata存草稿的时机就不对了，这里手动触发一次videodata save操作。
            NSString *videoPath = [AWEDraftUtils generateDraftPathFromTaskId:taskID];
            [ACCEditVideoDataConsumer saveVideoData:videoData toFileUsePropertyListSerialization:videoPath completion:nil];
        }
    };

    NSString *taskID = publishModel.repoDraft.taskID;
    // 静默合成不导入，避免图片被拉伸
    if (ACCConfigBool(kConfigBool_single_photo_upload_optimization) &&
        !publishModel.repoContext.isSilentMergeMode) {
        [videoData updatePhotoAssetsImageInfoWithImage:image asset:videoData.videoAssets.firstObject];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            writeDataBlock(taskID);
        });
    } else {
        writeDataBlock(taskID);
    }
}

@end
