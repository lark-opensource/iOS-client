//
//  ACC CanvasStickerShareAsStoryConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Bing on 2021/5/13.
//

#import "ACCCanvasStickerShareAsStoryConfig.h"
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCCanvasStickerShareAsStoryConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        self.minimumScale = 0.5;
        self.maximumScale = 20;
        
        self.supportedGestureType = ACCConfigBool(ACCConfigBOOL_social_share_video_enable_interaction) ? ACCStickerGestureTypePan|ACCStickerGestureTypePinch : ACCStickerGestureTypeNone;
    }
    return self;
}

@end
