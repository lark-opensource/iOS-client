//
//  ACCRecordFrameSamplingDuetHandler.m
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/3/15.
//

#import "ACCRecordFrameSamplingDuetHandler.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>
#import <BDWebImage/UIImage+BDImageTransform.h>
#import "AWERepoDuetModel.h"

const static CGFloat kACCFrameWidthForUpload = 360;
const static CGFloat kACCFrameHeightForUpload = 640;

@implementation ACCRecordFrameSamplingDuetHandler

- (BOOL)shouldHandle:(id<ACCRecordFrameSamplingServiceProtocol>)samplingContext
{
    if ([super shouldHandle:samplingContext]) {
        return YES;
    }

    if (self.publishModel.repoDuet.isDuet && [self.publishModel.repoDuet.duetLayout isEqualToString:kACCDuetLayoutGreenScreen]) {
        return YES;
    }
    return NO;
}

- (UIImage *)preprocessFrame:(UIImage *)rawImage
{
    if (rawImage) {
        CGSize imageSize = CGSizeMake(kACCFrameWidthForUpload, kACCFrameHeightForUpload);
        UIImage *processedImage = [rawImage bd_imageByResizeToSize:imageSize contentMode:UIViewContentModeScaleToFill];
        return processedImage?:rawImage;
    }
    return rawImage;
}

- (void)samplingCompleted
{
    if ([self.publishModel.repoDuet.duetLayout isEqualToString:kACCDuetLayoutGreenScreen]) {
        // 主要消费方式是赋值给publish model
        self.publishModel.repoVideoInfo.fragmentInfo.lastObject.originalFramesArray = [self mutableSamplingFrames].copy;
    }
    [super samplingCompleted];
}

@end
