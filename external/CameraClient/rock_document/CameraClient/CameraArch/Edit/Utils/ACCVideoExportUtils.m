//
//  ACCVideoExportUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2020/11/2.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoCutSameModel.h"
#import "ACCVideoExportUtils.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/AWEVideoRecordOutputParameter.h>
#import <CreationKitArch/AWEAVMutableCompositionBuilderDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>


@implementation ACCVideoExportUtils

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
                   publishModel:(AWEVideoPublishViewModel *)publishModel
{
    return [ACCVideoExportUtils videoSizeForVideoData:videoData
                                        suggestedSize:suggestedSize
                                          repoContext:publishModel.repoContext
                                          repoCutSame:publishModel.repoCutSame
                                        repoVideoInfo:publishModel.repoVideoInfo];
}



+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
                    repoContext:(ACCRepoContextModel *)repoContext
                    repoCutSame:(AWERepoCutSameModel *)repoCutSame
                  repoVideoInfo:(AWERepoVideoInfoModel *)repoVideoInfo
{
    BOOL isCanvas = repoVideoInfo.canvasType != ACCVideoCanvasTypeNone;
    if (isCanvas) {
        return videoData.transParam.targetVideoSize;
    }
    
    BOOL isNewCutSame = repoCutSame.isNLECutSame || repoCutSame.isSmartFilming;
    if (isNewCutSame) {
        NSValue *value = [repoCutSame preferVideoSize];
        if (value) {
            return [value CGSizeValue];
        } else if (!CGSizeEqualToSize(suggestedSize, CGSizeZero)) {
            return suggestedSize;
        } else {
            return CGSizeMake(1080, 1920);
        }
    }
    
    BOOL isRecord = repoContext.videoSource == AWEVideoSourceCapture;
    return [self videoSizeForVideoData:videoData suggestedSize:suggestedSize isRecord:isRecord];
}

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
{
    return [self videoSizeForVideoData:videoData suggestedSize:suggestedSize isRecord:NO];
}

+ (CGSize)videoSizeForVideoData:(ACCEditVideoData *)videoData
                  suggestedSize:(CGSize)suggestedSize
                       isRecord:(BOOL)isRecord
{
    CGSize maxSize = suggestedSize;
    CGSize sourceSize = suggestedSize;
    if (ACC_FLOAT_EQUAL_ZERO(suggestedSize.width) || ACC_FLOAT_EQUAL_ZERO(suggestedSize.height)) {
        maxSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
    }
    
    CGFloat resolution = 1080;
    CGFloat scale = 0;
    
    for (AVAsset *avAsset in videoData.videoAssets) {
        AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        CGSize naturalSize = videoTrack.naturalSize;
        if (ACC_FLOAT_EQUAL_ZERO(naturalSize.width) || ACC_FLOAT_EQUAL_ZERO(naturalSize.height)) {
            naturalSize = maxSize;
        }
        
        CGSize temp = CGSizeApplyAffineTransform(naturalSize, videoTrack.preferredTransform);
        sourceSize = CGSizeMake(fabs(temp.width), fabs(temp.height));
        
        // handle rotate info
        AWEVideoCompositionRotateType rotateType;
        if (isRecord || videoData.videoAssets.count == 1) {
            rotateType = [self p_totalRotateWithVideoData:videoData];
        } else {
            rotateType = [self p_rotateWithAVAsset:avAsset videoData:videoData];
        }
        
        if (rotateType == AWEVideoCompositionRotateTypeRight || rotateType == AWEVideoCompositionRotateTypeLeft) {
            sourceSize = CGSizeMake(sourceSize.height, sourceSize.width);
        }
    
        CGFloat sourceScale = 16.0 / 9.0;
        if (sourceSize.width > 0) {
            sourceScale = sourceSize.height / sourceSize.width;
        }
        
        if (sourceScale >= 16.0 / 9.0) {
            scale = 16.0 / 9.0;
            break;
        }
        
        if (sourceScale > scale) {
            scale = sourceScale;
        }
    }
    
    if (videoData.videoAssets.count == 1) {
        sourceSize = [ACCVideoExportUtils validTargetSize:sourceSize suggestedSize:suggestedSize];
        AWELogToolError2(@"resolution", AWELogToolTagUpload, @"target size = %@", [NSValue valueWithCGSize:sourceSize]);
        
        return sourceSize;
    }
    
    CGFloat width = 0;
    CGFloat height = 0;
    if (scale > 1) {
        width = resolution;
        height = width * scale;
    } else if (scale > 0) {
        height = resolution;
        width = height / scale;
    }
    sourceSize = CGSizeMake(width, height);
    sourceSize = [ACCVideoExportUtils validTargetSize:sourceSize suggestedSize:suggestedSize];
    AWELogToolError2(@"resolution", AWELogToolTagUpload, @"target size = %@", [NSValue valueWithCGSize:sourceSize]);
    
    return sourceSize;
}

+ (CGSize)validTargetSize:(CGSize)size suggestedSize:(CGSize)suggestedSize
{
    CGSize maxSize = suggestedSize;
    if (ACC_FLOAT_EQUAL_ZERO(suggestedSize.width) || ACC_FLOAT_EQUAL_ZERO(suggestedSize.height)) {
        maxSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
    }
    
    if (MAX(size.width, size.height) > MAX(maxSize.width, maxSize.height) ||
        MIN(size.width, size.height) > MIN(maxSize.width, maxSize.height)) {
        CGFloat width = MIN(maxSize.width, maxSize.height);
        CGFloat height = MAX(maxSize.width, maxSize.height);
        
        if (size.width > size.height) {
            width = MAX(maxSize.width, maxSize.height);
            height = MIN(maxSize.width, maxSize.height);
        }
        
        CGRect bounding = CGRectMake(0, 0, width, height);
        CGSize targetSize = AVMakeRectWithAspectRatioInsideRect(size, bounding).size;
        
        targetSize = [ACCVideoExportUtils checkReturnSize:targetSize suggestedSize:suggestedSize];
        return targetSize;
    }
    
    size = [ACCVideoExportUtils checkReturnSize:size suggestedSize:suggestedSize];
    return size;
}

/// check valid
+ (CGSize)checkReturnSize:(CGSize)size suggestedSize:(CGSize)suggestedSize
{
    CGSize maxSize = suggestedSize;
    if (ACC_FLOAT_EQUAL_ZERO(suggestedSize.width) || ACC_FLOAT_EQUAL_ZERO(suggestedSize.height)) {
        maxSize = [AWEVideoRecordOutputParameter maximumImportCompositionSize];
    }
    
    if (isnan(size.width) || size.width < 0.01) {
        AWELogToolError2(@"resolution", AWELogToolTagImport, @"unexpected checkReturnSize width.");
        return maxSize;
    }
    
    if (isnan(size.height) || size.height < 0.01) {
        AWELogToolError2(@"resolution", AWELogToolTagImport, @"unexpected checkReturnSize height.");
        return maxSize;
    }
    
    return size;
}

#pragma mark - Rotate Utils

+ (AWEVideoCompositionRotateType)p_totalRotateWithVideoData:(ACCEditVideoData *)videoData
{
    CGFloat angle = atan2f(videoData.importTransform.b, videoData.importTransform.a);
    if (ACC_FLOAT_EQUAL_TO(angle, M_PI_2)) {
        return AWEVideoCompositionRotateTypeRight;
    }
    if (ACC_FLOAT_EQUAL_TO(angle, M_PI)) {
        return AWEVideoCompositionRotateTypeDown;
    }
    if (ACC_FLOAT_EQUAL_TO(angle, -M_PI_2)) {
        return AWEVideoCompositionRotateTypeLeft;
    }
    
    return AWEVideoCompositionRotateTypeNone;
}

+ (AWEVideoCompositionRotateType)p_rotateWithAVAsset:(AVAsset *)asset videoData:(ACCEditVideoData *)videoData
{
    CGFloat degree = [videoData.assetRotationsInfo objectForKey:asset].floatValue;

    if (ACC_FLOAT_EQUAL_TO(degree, 90)) {
        return AWEVideoCompositionRotateTypeRight;
    }
    if (ACC_FLOAT_EQUAL_TO(degree, 180)) {
        return AWEVideoCompositionRotateTypeDown;
    }
    if (ACC_FLOAT_EQUAL_TO(degree, 270)) {
        return AWEVideoCompositionRotateTypeLeft;
    }
    
    return AWEVideoCompositionRotateTypeNone;
}

@end
