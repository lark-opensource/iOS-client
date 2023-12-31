//
//  ACCCanvasSinglePhotoStickerConfig.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/12.
//

#import "ACCCanvasSinglePhotoStickerConfig.h"
#import "ACCFriendsServiceProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>

@implementation ACCCanvasSinglePhotoStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.boxMargin = UIEdgeInsetsMake(CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX, CGFLOAT_MAX);
        self.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id  _Nullable contextId, UIGestureRecognizer * _Nonnull gestureRecognizer) {
            if (![IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].isInteractionEnabled) {
                return NO;
            }
            if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && gestureRecognizer.numberOfTouches < 2) {
                return NO;
            }
            if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
                return NO;
            }
            return YES;
        };
    }
    return self;
}

@end
