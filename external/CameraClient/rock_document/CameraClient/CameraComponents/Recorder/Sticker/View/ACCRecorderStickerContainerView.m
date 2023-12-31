//
//  ACCRecorderStickerContainerView.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/27.
//

#import <CreativeKitSticker/ACCStickerContainerView+Internal.h>

#import "ACCRecorderStickerContainerView.h"

@implementation ACCRecorderStickerContainerView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self || tmpView == [self containerView]) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

@end
