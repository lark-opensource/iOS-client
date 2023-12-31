//
//  ACCTapBubbleBackgroundView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/3.
//

#import "ACCTapBubbleBackgroundView.h"

@implementation ACCTapBubbleBackgroundView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if(hitView == self){
        if ([self.delegate respondsToSelector:@selector(bubbleBackgroundViewTap:)]) {
            [self.delegate bubbleBackgroundViewTap:point];
        }
        return nil;
    }
    return hitView;
}
@end
