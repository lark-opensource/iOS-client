//
//  AWEStoryTextImageModel+WidthLimit.m
//  CameraClient-Pods-Aweme
//
//  Created by shaohua on 2021/5/29.
//

#import "AWEStoryTextImageModel+WidthLimit.h"
#import <objc/runtime.h>

@implementation AWEStoryTextImageModel (WidthLimit)

- (CGFloat)widthLimit
{
    return [objc_getAssociatedObject(self, @selector(widthLimit)) floatValue];
}

- (void)setWidthLimit:(CGFloat)widthLimit
{
    objc_setAssociatedObject(self, @selector(widthLimit), @(widthLimit), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
