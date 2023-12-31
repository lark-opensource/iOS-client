//
//  AWEDuetCalculateUtil.m
//  Pods
//
//  Created by 郝一鹏 on 2019/4/15.
//

#import "AWEDuetCalculateUtil.h"
#import <CreativeKit/ACCMacros.h>

@implementation AWEDuetCalculateUtil

+ (NSArray *)duetBoundsInfoArrayForPublishModelVideo:(ACCEditVideoData *)video;
{
    CGSize outputSize = video.transParam.videoSize;
    if (ACC_FLOAT_EQUAL_ZERO(outputSize.width) ||
        outputSize.width < 0 ||
        ACC_FLOAT_EQUAL_ZERO(outputSize.height) ||
        outputSize.height < 0) {
        return nil;
    }
    CGFloat actualWidth = outputSize.width / 2;
    CGFloat actualHeight = actualWidth * outputSize.height / outputSize.width;
    return @[@{
                 @"s" : @((long)0),
                 @"e" : @((long)(video.totalVideoDuration * 1000)),
                 @"x" : @((long)0),
                 @"y" : @((long)0),
                 @"w" : @((long)actualWidth),
                 @"h" : @((long)actualHeight)
                 },
             ];
}

@end
