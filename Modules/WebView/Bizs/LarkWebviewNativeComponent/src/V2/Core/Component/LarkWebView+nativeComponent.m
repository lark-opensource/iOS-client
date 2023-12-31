//
//  LarkWebView+nativeComponent.m
//  LarkWebviewNativeComponent
//
//  Created by laisanpin on 2022/1/18.
//

#import "LarkWebView+nativeComponent.h"
#import <LarkwebViewNativeComponent/LarkwebViewNativeComponent-Swift.h>
#import <LKLoadable/Loadable.h>

@implementation LarkWebView (nativeComponent)
+ (void)lwnc_hookMethod {
    [self lkw_swizzleOriginInstanceMethod:@selector(pointInside:withEvent:) withHookInstanceMethod:@selector(lkwn_pointInside:with:)];
}
@end

LoadableRunloopIdleFuncBegin(LarkWebViewExtensionHook)
[LarkWebView lwnc_hookMethod];
LoadableRunloopIdleFuncEnd(LarkWebViewExtensionHook)
