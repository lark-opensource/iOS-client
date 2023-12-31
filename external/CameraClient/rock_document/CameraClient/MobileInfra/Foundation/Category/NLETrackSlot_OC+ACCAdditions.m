//
//  NLETrackSlot_OC+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import "NLETrackSlot_OC+ACCAdditions.h"

@implementation NLETrackSlot_OC (ACCAdditions)

- (NLESegmentSticker_OC *)sticker
{
    if ([self.segment isKindOfClass:[NLESegmentSticker_OC class]]) {
        return (NLESegmentSticker_OC *)self.segment;
    }
    return nil;
}

@end
