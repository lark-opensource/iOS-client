//
//  ACCDummyHitTestWindow.m
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/10.
//

#import "ACCDummyHitTestView.h"

#import <CreativeKit/ACCMacros.h>

@implementation ACCDummyHitTestView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    __auto_type hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        ACCBLOCK_INVOKE(self.hitTestHandler);
        return nil;
    } else {
        return hitView;
    }
}

@end
