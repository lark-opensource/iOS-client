//
//  TMAButton.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/19.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMAButton.h"

@implementation TMAButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect rect = self.bounds;

    // top
    rect.origin.y += _touchInsets.top;
    rect.size.height -= _touchInsets.top;
    // left
    rect.origin.x += _touchInsets.left;
    rect.size.width -= _touchInsets.left;
    // bottom
    rect.size.height -= _touchInsets.bottom;
    // right
    rect.size.width -= _touchInsets.right;

    if (CGRectContainsPoint(rect, point)) {
        return YES;
    }

    return [super pointInside:point withEvent:event];
}

@end
