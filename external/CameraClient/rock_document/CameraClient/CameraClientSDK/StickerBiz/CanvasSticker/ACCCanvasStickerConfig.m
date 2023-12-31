//
//  ACCCanvasStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2020/12/28.
//

#import "ACCCanvasStickerConfig.h"

@implementation ACCCanvasStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gesture) {
            return NO;
        };
        self.minimumScale = 0.5;
        self.maximumScale = 20;
    }
    return self;
}

- (NSArray<ACCStickerBubbleConfig *> *)bubbleActionList
{
    return @[];
}

@end
