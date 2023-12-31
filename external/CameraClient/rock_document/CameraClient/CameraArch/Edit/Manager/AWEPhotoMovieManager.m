//
//  AWETransitionTypeManager.m
//  AWEStudio
//
//  Created by 黄鸿森 on 2018/3/25.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEPhotoMovieManager.h"

@implementation AWEPhotoMovieManager

#pragma mark - Resource Manager

+ (NSInteger)audioRepeatCountForVideo:(AVAsset *)videoAsset
                           audioAsset:(AVAsset *)audioAsset
{
    if (audioAsset == nil || videoAsset == nil) {
        return 1;
    }
    CMTime videoDuration = videoAsset.duration;
    CMTime audioDuration = audioAsset.duration;
    if (audioDuration.timescale == 0.f || videoDuration.timescale == 0.f) {
        return 1;
    }
    NSTimeInterval videoDurationInSeconds = videoDuration.value / videoDuration.timescale;
    NSTimeInterval audioDurationInSeconds = audioDuration.value / audioDuration.timescale;
    
    if (audioDurationInSeconds == 0.f) {
        return 1;
    }
    return videoDurationInSeconds / audioDurationInSeconds + 1;
}

@end
