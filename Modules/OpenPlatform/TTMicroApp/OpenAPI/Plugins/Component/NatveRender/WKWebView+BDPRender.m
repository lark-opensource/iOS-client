//
//  WKWebView+BDPRender.h
//  Timor
//
//  Created by MacPu on 2019/7/15.
//

#import "WKWebView+BDPRender.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/NSObject+BDPExtension.h>
#import <LarkWebViewContainer/LarkWebView.h>
#import <ECOInfra/OPMacroUtils.h>
#import <ECOInfra/BDPLog.h>

#import <OPFoundation/BDPUtils.h>
#import "BDPNativeRenderObj.h"

#import <objc/runtime.h>
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>
#import <LarkWebViewContainer/UIView+removeFromSuperview.h>
#import <LarkWebViewContainer/LKNativeRenderDelegate.h>
#import <OPFoundation/EEFeatureGating.h>
#define COMPLETION(...) \
if (completion) {\
    completion(__VA_ARGS__);\
}

@interface UIScrollView (BDPRenderHook)

@property (nonatomic, strong) BDPNativeRenderObj *bdp_renderObject;

@end

@interface WKWebView (BDPRenderPrivate)

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPNativeRenderObj *> *bdp_renderObjs;
@property (nonatomic, strong) UIGestureRecognizer *bdp_touchActionGestureRecognizer;
@property (nonatomic, strong) UIView *bdp_currentHittestView;

///  重新渲染
- (void)renderAgain:(NSString *)index;

@end

@implementation UIScrollView(BDPRenderHook)

- (void)bdp_dealloc
{
    // 如果 scrollView 释放的时候，webview 还没有释放，就证明只是dom变了，需要重新去插入元素。
    BDPNativeRenderObj *renderObj = self.bdp_renderObject;
    if (renderObj.viewId && renderObj.webView) {
        [renderObj.webView renderAgain:renderObj.viewId];
    }
    [self bdp_dealloc];
}

#pragma mark -  Association Object

- (void)setBdp_renderObject:(BDPNativeRenderObj *)bdp_renderObject
{
    objc_setAssociatedObject(self, @selector(bdp_renderObject), bdp_renderObject, OBJC_ASSOCIATION_RETAIN);
    [self bdp_isaSwizzleInstance:NSSelectorFromString(@"dealloc") withHookInstnceMethod:@selector(bdp_dealloc)];
}

- (BDPNativeRenderObj *)bdp_renderObject
{
    return objc_getAssociatedObject(self, @selector(bdp_renderObject));
}

@end

@implementation WKWebView (BDPRender)

- (void)setBdp_disableShareHitTest:(BOOL)bdp_disableShareHitTest
{
    objc_setAssociatedObject(self, @selector(bdp_disableShareHitTest), @(bdp_disableShareHitTest), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)bdp_disableShareHitTest
{
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(bdp_disableShareHitTest)) boolValue];
}

- (void)setBdp_renderFixManager:(RenderFixManager *)bdp_renderFixManager
{
    objc_setAssociatedObject(self, @selector(bdp_renderFixManager), bdp_renderFixManager, OBJC_ASSOCIATION_RETAIN);
}

- (RenderFixManager *)bdp_renderFixManager
{
    RenderFixManager *manager = objc_getAssociatedObject(self, @selector(bdp_renderFixManager));
    if (!manager) {
        manager = [[RenderFixManager alloc] init];
        [self setBdp_renderFixManager:manager];
    }
    return manager;
}


- (void)bdp_hook
{
    BOOL disableShareHittest = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyNativeComponentDisableShareHitTest];
    self.bdp_disableShareHitTest = disableShareHittest;
    /*
     问题：新旧同层小程序的一个webview上显示时，swizzle 同一个instance会导致后面的实效，从而导致后者不响应hittest
     解决办法：是hook的hittest能够同时响应新旧同层的native view，disableShareHittest默认false，表示不禁止这个解决办法
     */
    if ([self isKindOfClass:[LarkWebView class]] && !self.bdp_disableShareHitTest) {
        WeakSelf;
        // 注入旧同层元素查找能力到新同层
        [((LarkWebView *)self) registerNativeRenderFindViewCallback:^UIView * _Nullable(UIView * _Nonnull view) {
            StrongSelf;
            BDPNativeRenderObj *nativeObj = nil;
            for (BDPNativeRenderObj *obj in [self.bdp_renderObjs allValues]) {
                if (obj.scrollView == view && view == obj.nativeView.superview) {
                    nativeObj = obj;
                    break;
                }
            }
            return nativeObj.nativeView;
        }];

    }
    // hook 该webview 的 hitTest，
    [self bdp_isaSwizzleInstance:@selector(hitTest:withEvent:) withHookInstnceMethod:@selector(bdp_hitTest:withEvent:)];
    // hook becomeFirstResponder方法
    [self bdp_isaSwizzleInstance:@selector(becomeFirstResponder) withHookInstnceMethod:@selector(bdp_becomeFirstResponder)];
}

- (void)bdp_insertComponent:(UIView *)view atIndex:(NSString *)index completion:(void (^)(BOOL))completion
{
    // 如果这个控件已经插入了，就不用重新插入了。
    if ([self.bdp_renderObjs objectForKey:index]) {
        BDPNativeRenderObj *obj = [self.bdp_renderObjs objectForKey:index];
        if (obj.scrollView) {
            COMPLETION(YES);
            return;
        }
    }
    
    // 查找 需要插入到的 scrollView
    WeakSelf;
    [self attachWebScrollViewByIndex:index tryCount:0 completion:^(UIScrollView *scrollView) {
        StrongSelfIfNilReturn;
        if (scrollView) {
            BDPNativeRenderObj *obj = [[BDPNativeRenderObj alloc] init];
            obj.scrollView = scrollView;
            obj.nativeView = view;
            obj.viewId = index;
            obj.webView = self;
            [self.bdp_renderObjs setObject:obj forKey:index];
            
            [scrollView setContentOffset:CGPointZero];
            scrollView.bdp_renderObject = obj;
            view.bdp_origin = CGPointZero;
            view.bdp_size = scrollView.bdp_size;
            [scrollView addSubview:view];
            
            [self.bdp_renderFixManager hookWithNativeView:view superview:scrollView];
            
            // 这里不用担心反复hook的问题。
            [self bdp_hook];
            COMPLETION(YES);
            return;
        }
        COMPLETION(NO);
    }];
}

- (BOOL)bdp_removeComponentAtIndex:(NSString *)index
{
    BDPNativeRenderObj *obj = [self.bdp_renderObjs objectForKey:index];
    if (obj) {
        [obj.nativeView removeFromSuperview];
        [self.bdp_renderObjs removeObjectForKey:index];
        return YES;
    }
    return NO;
}

- (UIView *)bdp_componentFromIndex:(NSString *)index
{
    BDPNativeRenderObj *obj = [self.bdp_renderObjs objectForKey:index];
    return obj.nativeView;
}

- (void)renderAgain:(NSString *)index
{
    // 重新渲染， 当dom改变的时候，wk会重新生成Scroll，所以需要在上一个scroll消失的时候，重新渲染到wk里面。
    BDPNativeRenderObj *obj = [self.bdp_renderObjs objectForKey:index];
    if (obj.nativeView) {
        [self bdp_insertComponent:obj.nativeView atIndex:obj.viewId completion:nil];
    }
}

#pragma mark - AssociateObject

- (void)setBdp_renderObjs:(NSMutableDictionary *)renderObjs
{
    objc_setAssociatedObject(self, @selector(bdp_renderObjs), renderObjs, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary<NSNumber *, BDPNativeRenderObj *> *)bdp_renderObjs
{
    NSMutableDictionary *objs = objc_getAssociatedObject(self, @selector(bdp_renderObjs));
    if (!objs) {
        objs = [[NSMutableDictionary alloc] initWithCapacity:10];
        self.bdp_renderObjs = objs;
    }
    return objs;
}

- (void)setBdp_touchActionGestureRecognizer:(UIGestureRecognizer *)bdp_touchActionGestureRecognizer
{
      objc_setAssociatedObject(self, @selector(bdp_touchActionGestureRecognizer), bdp_touchActionGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIGestureRecognizer *)bdp_touchActionGestureRecognizer
{
    UIGestureRecognizer *gesture = objc_getAssociatedObject(self, @selector(bdp_touchActionGestureRecognizer));
    if (gesture) {
        return gesture;
    }
    
    UIView *contentView = [self bdp_findWebContentView:self];
    
    for (UIGestureRecognizer *gesture in contentView.gestureRecognizers) {
        if ([gesture isKindOfClass:NSClassFromString(@"WKTouchActionGestureRecognizer")]) {
            self.bdp_touchActionGestureRecognizer = gesture;
            return gesture;
        }
    }
    return nil;
}

- (void)setBdp_currentHittestView:(UIView *)bdp_currentHittestView
{
    objc_setAssociatedObject(self, @selector(bdp_currentHittestView), bdp_currentHittestView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)bdp_currentHittestView
{
    return objc_getAssociatedObject(self, @selector(bdp_currentHittestView));
}

#pragma mark - find target component view

///  查找需要渲染的scrollView
- (void)attachWebScrollViewByIndex:(NSString *)index tryCount:(NSInteger)trycount completion:(void (^)(UIScrollView *scrollView))completion
{
    UIScrollView *scrollView = [self findScrollViews:self.scrollView index:index];
    
    if (scrollView) {
        scrollView.scrollEnabled = NO;
        COMPLETION(scrollView);
    } else if(++trycount < 20) {
        // 因为dom的渲染时机不确定，所以需要有一个重试的机制。
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(trycount * 4 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn
            [self attachWebScrollViewByIndex:index tryCount:trycount completion:completion];
        });
    } else {
        COMPLETION(nil);
        BDPLogDebug(@"[BDP-Native] insert failed");
    }
}

- (UIScrollView *)attachWebScrollViewByIndex:(NSString *)index
{
    UIScrollView *scrollView = [self findScrollViews:self.scrollView index:index];
    if (scrollView) {
        scrollView.scrollEnabled = NO;
    }
    return scrollView;
}

- (UIScrollView *)findScrollViews:(UIView *)view index:(NSString *)index
{
    if ([view isKindOfClass:UIScrollView.class] && view != self.scrollView) {
        UIScrollView *scroll = (UIScrollView *)view;
        if ([self calNativeViewByIndex:index scrollView:scroll]) {
            return (UIScrollView *)view;
        }
    }
    
    for (UIView *subview in view.subviews) {
        UIScrollView *ret = [self findScrollViews:subview index:index];
        if (ret) {
            return ret;
        }
    }
    return nil;
}

- (BOOL)calNativeViewByIndex:(NSString *)index scrollView:(UIScrollView *)scrollView
{
    UIView *superview = scrollView.superview;
    if ([superview isKindOfClass:NSClassFromString(@"WKCompositingView")]) {
        if (superview.layer.sublayers.count > 0) {
            // 发现 WKComponsitionView 的第一个layer是背景色的layer。专门用于显示背景的。
            // id 就是这个layer的背景色。
            CALayer *layer = superview.layer.sublayers[0];
            if (layer.backgroundColor) {
                const CGFloat *components = CGColorGetComponents(layer.backgroundColor);
                NSString *red = [self toHex:components[0] * 255];
                NSString *green = [self toHex:components[1] * 255];
                NSString *blue =  [self toHex:components[2] * 255];
                NSString *alpha = [self toHex:components[3] * 255];
                if ([alpha isEqualToString:@"01"]) {  // 如果是 ‘00’， 系统优化就不会渲染了，所以写成01。
                    NSString *viewId = [NSString stringWithFormat:@"%@%@%@", red, green, blue];
                    // 如果id 和背景色一样，表示就是这个scrollView。
                    return [index isEqualToString:viewId];
                }
            }
        }
    }
    return NO;
}

///  十进制转成16进制的字符串。
- (NSString *)toHex:(uint16_t)decimal
{
    NSString *str =@"";
    uint16_t remainder;
    static NSString *hexStr = @"0123456789abcdef";
    while (decimal > 0) {
        remainder = decimal % 16;
        decimal = decimal / 16;
        str = [[hexStr substringWithRange:NSMakeRange(remainder, 1)] stringByAppendingString:str];
    }
    if (str.length < 2) {
        str = [@"00" stringByReplacingCharactersInRange:NSMakeRange(2 - str.length, str.length) withString:str];
    }
    
    return str;
}

#pragma mark - hittest

- (UIView *)bdp_findWebContentView:(UIView *)webview
{
    if ([webview isKindOfClass:NSClassFromString(@"WKContentView")]) {
        return webview;
    }
    
    for (UIView *subView in webview.subviews) {
        UIView *view = [self bdp_findWebContentView:subView];
        if (view) return view;
    }
    return nil;
}

/// 复写WK的hitTest，实现手势传递的问题，之前说的用 WKNativelyInteractible Protocol协议在老版本不支持。
- (UIView *)bdp_hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // enable WKTouchActionGestureRecognizer
    if (@available(iOS 13.0, *)) {
        // 如果是iOS 13系统，需要先恢复 WKTouchActionGestureRecognizer，不要影响WK的正常手势
        self.bdp_touchActionGestureRecognizer.enabled = YES;
    }
    
    UIView *view = [self bdp_hitTest:point withEvent:event];
    if (![view isKindOfClass:[UIScrollView class]]) {
        self.bdp_currentHittestView = nil;
        return view;
    } else if ([view isKindOfClass:[UITextView class]]) {
        // UITextView也是UIScrollView， 如果hittest得到的时UITextView，就直接返回
        self.bdp_currentHittestView = view;
        return view;
    }
    
    BDPNativeRenderObj *nativeObj = nil;
    for (BDPNativeRenderObj *obj in [self.bdp_renderObjs allValues]) {
        if (obj.scrollView == view && view == obj.nativeView.superview) {
            nativeObj = obj;
            break;
        }
    }
    UIView *nativeView = nativeObj.nativeView;
    if (!nativeView && [self isKindOfClass:[LarkWebView class]] && !self.bdp_disableShareHitTest) {
        // 如果bdp_renderObjs 没有同层元素，则从其他同层元素队列中查找
        nativeView = [(LarkWebView *)self findNativeViewWithView:view];
    }
    if (nativeView) {
        CGPoint pt = [self convertPoint:point toView:nativeView];
        UIView *ret = [nativeView hitTest:pt withEvent:event];
        // disable WKTouchActionGestureRecognizer
        if (@available(iOS 13.0, *)) {
            self.bdp_touchActionGestureRecognizer.enabled = NO;
        }
        self.bdp_currentHittestView = ret;
        return ret ?: view;
    }
    self.bdp_currentHittestView = nil;
    return view;
}

/// 复写becomeFirstResponder， 解决textArea每次都会被resignFirstResponder的问题
- (BOOL)bdp_becomeFirstResponder
{
    if (self.bdp_currentHittestView) {
        return NO;
    }
    return [self bdp_becomeFirstResponder];
}

@end
