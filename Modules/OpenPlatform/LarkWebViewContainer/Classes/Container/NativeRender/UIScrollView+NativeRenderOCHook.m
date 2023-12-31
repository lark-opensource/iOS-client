//
//  NativeRenderOCHook.m
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/12/15.
//

#import "UIScrollView+NativeRenderOCHook.h"
#import <objc/runtime.h>
#import "NSObject+RuntimeExtension.h"
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>
@implementation UIScrollView(NativeRenderOC)

- (void)lk_native_render_dealloc
{
    // 修复 dealloc 里面使用weak 是为nil的 bug
    NativeRenderObj *renderObj = self.lkw_renderObject;

    if (renderObj.viewId && renderObj.webview) {
        [renderObj.webview renderAgainWithIndex:renderObj.viewId];
    }
    [self lk_native_render_dealloc];
}

- (void)setLkw_renderObject:(NativeRenderObj *)lkw_renderObject
{
    objc_setAssociatedObject(self, @selector(lkw_renderObject), lkw_renderObject, OBJC_ASSOCIATION_RETAIN);
    [self lkw_swizzleInstanceClassIsa:NSSelectorFromString(@"dealloc") withHookInstanceMethod:@selector(lk_native_render_dealloc)];
}

- (NativeRenderObj *)lkw_renderObject
{
    return objc_getAssociatedObject(self, @selector(lkw_renderObject));
}

/// 新同层渲染hook UIScrollView dealloc
- (void)lk_native_sync_render_dealloc
{
    // 修复 dealloc 里面使用weak 是为nil的 bug
    NativeRenderObj *renderObj = self.lkw_syncRenderObject;
    [renderObj renderSyncAgain];
    
    [self lk_native_sync_render_dealloc];
}

- (void)setLkw_syncRenderObject:(NativeRenderObj *)lkw_syncRenderObject {
    objc_setAssociatedObject(self, @selector(lkw_syncRenderObject), lkw_syncRenderObject, OBJC_ASSOCIATION_RETAIN);
    [self lkw_swizzleInstanceClassIsa:NSSelectorFromString(@"dealloc") withHookInstanceMethod:@selector(lk_native_sync_render_dealloc)];
}

- (NativeRenderObj *)lkw_syncRenderObject {
    return objc_getAssociatedObject(self, @selector(lkw_syncRenderObject));
}


#pragma mark -  Association Object

@end
