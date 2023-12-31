//
//  AWEStudioExcludeSelfView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEStudioExcludeSelfView.h"

@implementation AWEStudioExcludeSelfView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}

@end
