//
//  AWEVideoPublishViewModel+ACCPreviewEdge.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import "AWEVideoPublishViewModel+ACCPreviewEdge.h"
#import <objc/runtime.h>

@implementation AWEVideoPublishViewModel (ACCPreviewEdge)

- (void)setBackFromEditPage:(BOOL)backFromEditPage
{
    objc_setAssociatedObject(self, @selector(backFromEditPage), @(backFromEditPage), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)backFromEditPage
{
    return [objc_getAssociatedObject(self, @selector(backFromEditPage)) boolValue];
}

- (void)setPreMergeInProcess:(BOOL)preMergeInProcess
{
    objc_setAssociatedObject(self, @selector(preMergeInProcess), @(preMergeInProcess), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)preMergeInProcess
{
    return [objc_getAssociatedObject(self, @selector(preMergeInProcess)) boolValue];
}

- (void)setOriginalPlayerFrame:(CGRect)originalPlayerFrame
{
    objc_setAssociatedObject(self, @selector(originalPlayerFrame), [NSValue valueWithCGRect:originalPlayerFrame], OBJC_ASSOCIATION_RETAIN);
}

- (CGRect)originalPlayerFrame
{
    return [objc_getAssociatedObject(self, @selector(originalPlayerFrame)) CGRectValue];
}

@end
