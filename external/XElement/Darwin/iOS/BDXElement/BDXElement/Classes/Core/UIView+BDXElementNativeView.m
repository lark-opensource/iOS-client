// Copyright 2022 The Lynx Authors. All rights reserved.

#import "UIView+BDXElementNativeView.h"
#import <objc/runtime.h>

@implementation UIView (BDXElementNativeView)

- (UIView *)bdx_viewWithName:(NSString *)name
{
    if ([self.bdx_nativeViewName isEqualToString:name]) {
        return self;
    }
     
    for (UIView *subview in self.subviews) {
        UIView *resultView = [subview bdx_viewWithName:name];
        if (resultView) {
            return resultView;
        }
    }
    return nil;
}

- (NSString *)bdx_nativeViewName
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBdx_nativeViewName:(NSString *)name
{
    objc_setAssociatedObject(self, @selector(bdx_nativeViewName), name, OBJC_ASSOCIATION_COPY);
}

@end
