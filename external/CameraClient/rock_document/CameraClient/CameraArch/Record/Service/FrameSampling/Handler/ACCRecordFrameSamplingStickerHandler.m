//
//  ACCRecordFrameSamplingDefaultHandler.m
//  AAWELaunchOptimization
//
//  Created by limeng on 2020/5/11.
//

#import "ACCRecordFrameSamplingStickerHandler.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCSecurityFramesSaver.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import "AWERepoDuetModel.h"

@implementation ACCRecordFrameSamplingStickerHandler

- (BOOL)shouldHandle:(nonnull id<ACCRecordFrameSamplingServiceProtocol>)samplingContext
{
    if ([super shouldHandle:samplingContext]) {
        return YES;
    }
    AWERepoDuetModel *repoDuet=  self.publishModel.repoDuet;
    
    // Frame sampling of Duet with green screen layout will be handled by `ACCRecordFrameSamplingDuetHandler`
    if (repoDuet.isDuet && [repoDuet.duetLayout isEqualToString:kACCDuetLayoutGreenScreen]) {
        return NO;
    }
    // 1. 关闭原始帧录制模式时，不抽帧
    if (ACCConfigBool(kConfigBool_close_upload_origin_frames)) {
        return NO;
    }

    return YES;
}

- (void)samplingCompleted
{
    if (!ACCConfigInt(kConfigBool_close_upload_origin_frames)) {
        // 主要消费方式是赋值给publish model
        self.publishModel.repoVideoInfo.fragmentInfo.lastObject.originalFramesArray = [self mutableSamplingFrames].copy;
    }
    [super samplingCompleted];
}

- (BOOL)needAfterProcess
{
    // 所有道具都抽原始帧，包括绿幕道具
    return NO;
}

- (void)prepareToSampleFrame
{
    [super prepareToSampleFrame];
    
    [self saveBgPhotosForTakePicture];
}

- (void)saveBgPhotosForTakePicture
{
    NSMutableArray *stickerImages = [[NSMutableArray alloc] init];
    /// ⚠️ 道具换脸时，相册里选择的换脸图片，也需要上传审核
    if (self.faceImage) {
        [stickerImages acc_addObject:self.faceImage];
    }
    
    [stickerImages addObjectsFromArray:[self.frameSamplingContext.bgPhotos copy]];
    [stickerImages addObjectsFromArray:[self.frameSamplingContext.multiAssetsPixaloopSelectedImages copy]];
    AWEVideoFragmentInfo *currentFragment = self.publishModel.repoVideoInfo.fragmentInfo.lastObject;
    if (stickerImages.count > 0 && !currentFragment) {
        currentFragment = [[AWEVideoFragmentInfo alloc] initWithSourceType:AWEVideoFragmentSourceTypeRecord];
        [self.publishModel.repoVideoInfo.fragmentInfo addObject:currentFragment];
    }
    [ACCSecurityFramesSaver saveImages:stickerImages
                                  type:ACCSecurityFrameTypeProps
                                taskId:self.publishModel.repoDraft.taskID
                            completion:^(NSArray<NSString *> * _Nonnull paths, BOOL success, NSError * _Nonnull error) {
        currentFragment.stickerImageAssetPaths = paths;
    }];
}

#pragma mark - ACCEffectEvent

- (void)onEffectMessageReceived:(IESMMEffectMessage *)message
{
    if (IESMMEffectMsgOther == message.type) {
        NSDictionary *sdkExtra = [self.currentSticker pixaloopSDKExtra];
        if (sdkExtra && [sdkExtra acc_pixaloopLoading:@"pl"]) {
            // pixaloop loading 状态
            const NSInteger kPixaloopEffectBegin = 30;
            const NSInteger kPixaloopEffectEnd = 31;
            if (kPixaloopEffectBegin == message.msgId) {
                // do nothing
            } else if (kPixaloopEffectEnd == message.msgId) {
                // take a capture for security
                if (self.running) {
                    [self sampleFrame];
                } else {
                    [self sampleFrameForPixloop];
                }
            }
        }
    }
}

@end
