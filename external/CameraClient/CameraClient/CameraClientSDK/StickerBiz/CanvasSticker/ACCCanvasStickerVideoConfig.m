//
//  ACCCanvasStickerVideoConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/12.
//

#import "ACCCanvasStickerVideoConfig.h"

@implementation ACCCanvasStickerVideoConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing | ACCStickerContainerFeatureAngleAdsorbing | ACCStickerContainerFeatureHighlightMoment;
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gesture) {
            if ([gesture isKindOfClass:[UITapGestureRecognizer class]] || [gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
                return NO;
            }
            return YES;
        };
        self.minimumScale = 0.5;
        self.maximumScale = 20;
    }
    return self;
}

@end
