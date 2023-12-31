//
//  ACCPassThroughView.m
//  CameraClient
//
//  Created by liyingpeng on 2020/5/18.
//

#import "ACCPassThroughView.h"

@implementation ACCPassThroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if(hitView == self){
        return nil;
    }
    return hitView;
}

- (void)accessibilityElementDidBecomeFocused{
    if ([self.delegate respondsToSelector:@selector(passThroughViewDidBecomeFocused)]) {
        [self.delegate passThroughViewDidBecomeFocused];
    }
}

@end
