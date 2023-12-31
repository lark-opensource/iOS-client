//
//  ACCInteractionView.m
//  CameraClient-Pods-Aweme
//
//  Created by lihui on 2019/11/1.
//

#import "ACCInteractionView.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCInteractionView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    ACCBLOCK_INVOKE(self.interactionBlock);
    return [super hitTest:point withEvent:event];
}

//https://cony.bytedance.net/wiki/page/76
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:NSClassFromString(@"AWEAudioWaveformSliderView")] || [touch.view isKindOfClass:NSClassFromString(@"AWESlider")]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

@end
