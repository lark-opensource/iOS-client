//
//  ACCVideoHelper.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/2.
//

#import "ACCVideoHelper.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCVideoHelper

+ (CGSize)screenDisplaySizeForVideoSize:(CGSize)videoSize
{
    CGFloat width;
    CGFloat height;
    if (videoSize.height / videoSize.width <= ACC_SCREEN_HEIGHT / ACC_SCREEN_WIDTH) {
        width = floor(MIN(videoSize.width, ACC_SCREEN_WIDTH * [UIScreen mainScreen].scale));
        height = floor(width * videoSize.height / videoSize.width);
    } else {
        height = floor(MIN(videoSize.height, ACC_SCREEN_HEIGHT * [UIScreen mainScreen].scale));
        width = floor(height * videoSize.width / videoSize.height);
    }
    width = width - (int)width % 2;
    height = height - (int)height % 2;
    return CGSizeMake(width, height);
}

@end
