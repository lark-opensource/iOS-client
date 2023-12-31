//
//  AWEVideoRecorderARGestureDelegateModel.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/2/5.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEVideoRecorderARGestureDelegateModel.h"

@implementation AWEVideoRecorderARGestureDelegateModel

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
        return YES;
    }

    if ([otherGestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] && [gestureRecognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
        return YES;
    }

    return NO;
}

@end
