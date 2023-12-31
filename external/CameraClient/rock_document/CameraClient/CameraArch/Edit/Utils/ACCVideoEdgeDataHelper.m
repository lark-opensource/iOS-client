//
//  ACCVideoEdgeDataHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/7.
//

#import "AWERepoContextModel.h"
#import "ACCVideoEdgeDataHelper.h"
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import "AWEVideoRecordOutputParameter.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMacros.h>
#import <TTVideoEditor/IESVideoAddEdgeData.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>

@implementation ACCVideoEdgeDataHelper

+ (IESVideoAddEdgeData *)buildAddEdgeDataWithTranscoderParam:(IESMMTranscoderParam *)transParam publishModel:(AWEVideoPublishViewModel *)publishModel
{
    IESVideoAddEdgeData *edge = [[IESVideoAddEdgeData alloc] init];
    edge.red = 0;
    edge.green = 0;
    edge.blue = 0;
    // When using stickers outside the edges of the video, the SDK will force an external preset resolution.
    CGSize previewEdgeSize = CGSizeMake(publishModel.repoTranscoding.outputWidth, publishModel.repoTranscoding.outputHeight);
    CGSize maxExportSize = [AWEVideoRecordOutputParameter currentMaxExportSize];
    if (previewEdgeSize.width == 0 || previewEdgeSize.height == 0) {
        [AWEVideoRecordOutputParameter configPublishViewModelOutputParametersWith:publishModel];
        previewEdgeSize = CGSizeMake(publishModel.repoTranscoding.outputWidth, publishModel.repoTranscoding.outputHeight);
        AWELogToolError2(@"resolution", AWELogToolTagEdit, @"unexpected edge targetFrameSize is null, default previewEdgeSize:%@", NSStringFromCGSize(previewEdgeSize));
    } else if (previewEdgeSize.height > 0 && fabs(previewEdgeSize.width / previewEdgeSize.height - 9.0 / 16.0) > 0.1) {
        // Compatible with 16: 9 (default ve sdk)/(duet)/(MV/Status) preset transcoding size.
        CGSize originalSize = previewEdgeSize;
        transParam.videoSize = maxExportSize;
        previewEdgeSize = transParam.videoSize;
        AWELogToolError2(@"resolution", AWELogToolTagEdit, @"unexpected edge targetFrameSize:%@, originalSize:%@, maxExportSize:%@", NSStringFromCGSize(previewEdgeSize), NSStringFromCGSize(originalSize), NSStringFromCGSize(maxExportSize));
    }

    CGSize maxEditSize = [AWEVideoRecordOutputParameter currentMaxEditSize];
    CGSize customEdgeSize = [self p_customEdgeSizeWithPublishModel:publishModel];
    //单多图、MV影集、剪同款、时光故事这些图片类投稿画质增强需求要求根据单独的下发分辨率（高清:1080 * 1920）来保证全流程是高分辨率+高码率，但是这快和现有分辨率和码率的控制有并行，后面需要拉上相关同学统一对下这块，整合全链路的逻辑。
    //videos that using photos (photo to video/mv/cut same video/moments) need to support hd (high resolution + bitrates) post, we need to
    //discuss with related rds to make sure how to integration those logic with current logic.
    if (CGSizeEqualToSize(customEdgeSize, CGSizeZero)) {
        if ([AWEVideoRecordOutputParameter issourceSize:previewEdgeSize exceedLimitWithTargetSize:maxEditSize]) {
            CGSize originalSize = previewEdgeSize;
            CGSize targetSize = [AWEVideoRecordOutputParameter getSizeWithSourceSize:previewEdgeSize targetSize:maxEditSize];
            if (!CGSizeEqualToSize(targetSize, CGSizeZero)) {
                previewEdgeSize = targetSize;
            }
            AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"expected conversion edge targetFrameSize:%@, originalVideoSize:%@, limit size:%@", NSStringFromCGSize(previewEdgeSize), NSStringFromCGSize(originalSize), NSStringFromCGSize(maxEditSize));
        } else {
            AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"setupPreviewEdge targetFrameSize:%@, limit size:%@", NSStringFromCGSize(previewEdgeSize), NSStringFromCGSize(maxEditSize));
        }
    } else {
        previewEdgeSize = customEdgeSize;
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"setupPreviewEdge targetFrameSize:%@, limit size:%@ for photo/mv/cut_same/moments hd", NSStringFromCGSize(previewEdgeSize), NSStringFromCGSize(maxEditSize));
    }
    
    edge.targetFrameSize = previewEdgeSize;
    
    return edge;
}

+ (CGSize)p_customEdgeSizeWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    AWEVideoType videoType = publishModel.repoContext.videoType;
    CGSize defaultSize = CGSizeZero;
    CGSize hdSize = CGSizeMake(1080, 1920);

    if (videoType == AWEVideoTypePhotoToVideo) {
        return ACCConfigBool(kConfigBool_enable_1080p_photo_to_video) ? hdSize : defaultSize;
    }

    if (videoType == AWEVideoTypeMoments) {
        return ACCConfigBool(kConfigBool_enable_1080p_moments_video) ? hdSize : defaultSize;
    }

    if (videoType == AWEVideoTypeMV || videoType == AWEVideoTypeNewYearWish) {
        if (publishModel.repoCutSame.templateModel.effectModel == nil) {
            return ACCConfigBool(kConfigBool_enable_1080p_cut_same_video) ? hdSize : defaultSize;
        } else {
            return ACCConfigBool(kConfigBool_enable_1080p_mv_video) ? hdSize : defaultSize;
        }
    }
    if (publishModel.repoAudioMode.isAudioMode) {
        CGSize defaultAudioSize = CGSizeMake(720, 1280);
        return ACCConfigBool(kConfigBool_enable_1080p_photo_to_video) ? hdSize : defaultAudioSize;
    }
    return defaultSize;
}

+ (NSValue *)sizeValueOfViewWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSValue * sizeOfVideoValue = nil;
    BOOL predicate = publishModel.repoContext.videoType == AWEVideoTypeStoryPicture || publishModel.repoContext.isQuickStoryPictureVideoType || publishModel.repoContext.videoType == AWEVideoTypeStoryPicVideo;
    if (ACCConfigBool(kConfigBool_single_photo_upload_optimization)) {
        predicate = predicate || publishModel.repoVideoInfo.canvasType == ACCVideoCanvasTypeSinglePhoto;
    }
    if (predicate) {
        if (!CGSizeEqualToSize(publishModel.repoUploadInfo.toBeUploadedImage.size, CGSizeZero)) {
            sizeOfVideoValue = [NSValue valueWithCGSize:publishModel.repoUploadInfo.toBeUploadedImage.size];
        }
    } else {
        sizeOfVideoValue = [publishModel.repoVideoInfo sizeOfVideo];
    }
    if (sizeOfVideoValue && !AWECGSizeIsNaN(sizeOfVideoValue.CGSizeValue)) {
        return sizeOfVideoValue;
    }
    return nil;
}

@end
