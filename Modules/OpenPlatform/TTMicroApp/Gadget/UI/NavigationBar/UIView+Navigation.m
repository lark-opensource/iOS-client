//
//  UIView+Navigation.m
//  AFgzipRequestSerializer
//
//  Created by tujinqiu on 2019/10/8.
//

#import "UIView+Navigation.h"
#import <OPFoundation/NSObject+BDPExtension.h>
#import "BDPNavigationController.h"
#import <objc/runtime.h>
#import "UINavigationBar+Navigation.h"
#import <LKLoadable/Loadable.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

LoadableRunloopIdleFuncBegin(UIViewNavigationSwizzle)
[UIView performSelector:@selector(bdp_uiview_navigation_swizzle)];
LoadableRunloopIdleFuncEnd(UIViewNavigationSwizzle)

@implementation UIView (Navigation)
+ (void)bdp_uiview_navigation_swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSObject bdp_swizzleClass:objc_getClass([UINavigationBar bdp_backgroundViewClassString].UTF8String)
                          selector:@selector(setHidden:)
                     swizzledClass:[self class]
                  swizzledSelector:@selector(bdp_setHidden:)];
    });
}

- (void)bdp_setHidden:(BOOL)hidden
{
    UIResponder *responder = (UIResponder *)self;
    while (responder) {
        if ([responder isKindOfClass:[BDPNavigationController class]]) {
            [self bdp_setHidden:((BDPNavigationController *)responder).barBackgroundHidden];
            return;
        }
        responder = responder.nextResponder;
    }
    [self bdp_setHidden:hidden];
}

@end

