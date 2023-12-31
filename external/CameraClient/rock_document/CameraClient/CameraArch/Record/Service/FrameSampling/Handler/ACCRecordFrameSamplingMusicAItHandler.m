//
//  ACCRecordFrameSamplingMusicAItHandler.m
//  AAWELaunchOptimization
//
//  Created by limeng on 2020/5/11.
//

#import "ACCRecordFrameSamplingMusicAItHandler.h"
#import "AWEAIMusicRecommendManager.h"
#import "ACCConfigKeyDefines.h"
#import <BDWebImage/UIImage+BDImageTransform.h>

@implementation ACCRecordFrameSamplingMusicAItHandler

- (BOOL)shouldHandle:(nonnull id<ACCRecordFrameSamplingServiceProtocol>)samplingContext
{
    if ([super shouldHandle:samplingContext]) {
        return YES;
    }
    // 1.未关闭原视频帧上传时不走AI抽帧
    if (!ACCConfigBool(kConfigBool_close_upload_origin_frames)) {
        return NO;
    }
    // 2.有贴纸道具时不走AI抽帧
    if (self.currentSticker) {
        return NO;
    }
    // 3. 已经开始抽帧或当前publish model 在serviceOnWithModel 不走AI抽帧
    if (self.isRunning || ![[AWEAIMusicRecommendManager sharedInstance] serviceOnWithModel:self.publishModel]) {
        return NO;
    }
    return YES;
}

- (void)firstSampling
{
    // @note: 延时 0.5 秒是因为开拍时抽的帧效果不好，有抖动.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sampleFrame];
    });
}

- (void)sampleFrame
{
    // 非录制状态不抽帧
    if ([self.cameraService.cameraControl status] != IESMMCameraStatusRecording) {
        return;
    }
    
    [super sampleFrame];
}

- (void)samplingCompleted
{
    if ([[AWEAIMusicRecommendManager sharedInstance] serviceOnWithModel:self.publishModel] &&
        [AWEAIMusicRecommendManager sharedInstance].recordFrameType == AWEAIRecordFrameTypeRecord) {
        [[AWEAIMusicRecommendManager sharedInstance] appendFramePaths:[self immutableSamplingFrames]];
    }
    [super samplingCompleted];
}

- (UIImage *)preprocessFrame:(UIImage *)rawImage
{
    if (rawImage) {
        CGSize imageSize = CGSizeMake([AWEAIMusicRecommendManager sharedInstance].frameSizeForUpload, [AWEAIMusicRecommendManager sharedInstance].frameSizeForUpload);
        UIImage *processedImage = [rawImage bd_imageByResizeToSize:imageSize contentMode:UIViewContentModeScaleToFill];
        return processedImage?:rawImage;
    }
    return rawImage;
}

- (void)addFrameIfNeed:(UIImage *)processedImage
{
    [super addFrameIfNeed:processedImage];
    // @note: AI 抽帧只要 5 张，但拍摄时长可能大于 15 秒, 所以当抽的帧大于10张的时候，这个数组保留一半
    NSUInteger threshold = (2*[AWEAIMusicRecommendManager sharedInstance].maxNumForUpload + 1);
    [self reduceSamplingFramesByThreshold:threshold];
}

@end
