//
//  WKWebView+BDNativeWeb.m
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/6/15.
//  Copyright © 2019 liuyunxuan. All rights reserved.
//

#import "WKWebView+BDNativeWeb.h"
#import <objc/runtime.h>
#import "NSDictionary+BDNativeWebHelper.h"
#import "BDNativeWebBaseComponent.h"
#import "WKWebView+BDNativeWebBridge.h"
#import "BDNativeWebLogManager.h"
#import "BDNativeWebComponentLogic.h"
#import "BDNativeWebHookUtil.h"
#import "UIScrollView+BDNativeWeb.h"
#import <AWELazyRegister/AWELazyRegisterPremain.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>

@interface UIControl(BDNativeWeb)

@property (nonatomic, strong) NSNumber *bdNative_nativeStateTag;

@end

static const char * kNativeStateKey = "kNativeStateKey";

@implementation UIControl (BDNativeWeb)

- (void)setBdNative_nativeStateTag:(NSNumber *)bdNative_nativeStateTag {
    objc_setAssociatedObject(self, kNativeStateKey, bdNative_nativeStateTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)bdNative_nativeStateTag {
    NSNumber *number = objc_getAssociatedObject(self, kNativeStateKey);
    return number;
}

@end

@interface BDNativeWebWebViewObject : NSObject

@property (nonatomic, strong) BDNativeWebComponentLogic *componentLogic;

@end

@implementation BDNativeWebWebViewObject

@end

@interface WKWebView(BDNativeCategory)<BDNativeWebComponentLogicDelegate>
@property (nonatomic, strong) BDNativeWebWebViewObject *bdNative_webViewObject;
@property (nonatomic, strong) NSNumber *bdNative_enableNewHandleTouchInvalid;
@end

static const char * kNativeWebViewObject = "kNativeWebViewObject";
static const char * kBdnEnableNewHandleTouchInvalid = "kBdnEnableNewHandleTouchInvalid";

//static BOOL enableNewHandleTouchInvalid = NO;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation WKWebView(BDNativeCategory)
#pragma clang diagnostic pop

- (void)setBdNative_webViewObject:(BDNativeWebWebViewObject *)bdNative_webViewObject {
    objc_setAssociatedObject(self, kNativeWebViewObject, bdNative_webViewObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDNativeWebWebViewObject *)bdNative_webViewObject {
    return objc_getAssociatedObject(self, kNativeWebViewObject);
}

- (void)setBdNative_enableNewHandleTouchInvalid:(NSNumber *)bdNative_enableNewHandleTouchInvalid {
    objc_setAssociatedObject(self, kBdnEnableNewHandleTouchInvalid, bdNative_enableNewHandleTouchInvalid, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (NSNumber *)bdNative_enableNewHandleTouchInvalid {
    return objc_getAssociatedObject(self, kBdnEnableNewHandleTouchInvalid);
}


#pragma mark - Native Component Class Dict

@end

@implementation WKWebView (BDNativeWeb)

AWELazyRegisterPremainClassCategory(WKWebView,BDNativeWeb) {
    [self btd_swizzleInstanceMethod:@selector(hitTest:withEvent:)
                               with:@selector(bdNativeHitTest:withEvent:)];
}

- (void)bdNative_enableNative
{
    [self bdNative_enableNativeWithComponents:nil];
}

- (BOOL)bdNative_hasNativeEnabled
{
    return self.bdNative_webViewObject;
}

- (void)bdNative_enableNativeWithComponents:(NSArray<Class> *)components
{
    __weak typeof(self) weakSelf = self;
    if (self.bdNative_webViewObject)
    {
        NSAssert(NO, @"only enable once");
        return;
    }
    
    self.bdNative_webViewObject = [[BDNativeWebWebViewObject alloc] init];
    [self bdNativeBridge_enableBDNativeBridge];
    self.bdNative_webViewObject.componentLogic = [[BDNativeWebComponentLogic alloc] init];
    self.bdNative_webViewObject.componentLogic.delegate = self;
    [self.bdNative_webViewObject.componentLogic registerNativeComponent:components];

    
    [self bdNativeBridge_registerHandler:^(NSDictionary *params, BDNativeBridgeCallback callback) {
        [weakSelf.bdNative_webViewObject.componentLogic handleInvokeFunction:params completion:^(BOOL succeed, NSDictionary * _Nullable param) {
            if (callback) {
                if (succeed) {
                    callback(0,param,nil);
                } else {
                    callback(1,param,nil);
                }
            }
        }];
    } bridgeName:@"invoke"];
    
    [self bdNativeBridge_registerHandler:^(NSDictionary *params, BDNativeBridgeCallback callback) {
        [weakSelf.bdNative_webViewObject.componentLogic handleCallbackFunction:params completion:^(BOOL succeed, NSDictionary * _Nullable param) {
            
        }];
    } bridgeName:@"callback"];
}

+ (void)bdNative_registerGlobalNativeWithComponents:(NSArray<Class> *)components
{
    [BDNativeWebComponentLogic registerGloablNativeComponent:components];
}

- (void)bdNative_clearNativeComponent
{
    [self.bdNative_webViewObject.componentLogic clearNativeComponent];
}

- (void)bdNative_clearNativeComponentWithIFrameID:(NSString *)iFrameID {
    [self.bdNative_webViewObject.componentLogic clearNativeComponentWithIFrameID:iFrameID];
}


#pragma mark - private method
-(UIScrollView *)bdNative_findScrollViews:(UIView *)view index:(NSInteger)index scrollContentWidth:(NSInteger)scrollContentWidth
{
    if ([view isKindOfClass:UIScrollView.class] && view != self.scrollView) {
        UIScrollView *scroll = (UIScrollView *)view;
        if ([self bdNative_calNativeViewByIndex:index scrollView:scroll]) {
            return (UIScrollView *)view;
        }
    }
    
    for (UIView *subview in view.subviews)
    {
        UIScrollView *ret = [self bdNative_findScrollViews:subview index:index scrollContentWidth:scrollContentWidth];
        if (ret) {
            return ret;
        }
    }
    return nil;
}

- (BOOL)bdNative_isEmptyString:(NSString *)string
{
    return (!string || ![string isKindOfClass:[NSString class]] || string.length == 0);
}

- (NSString *)bdNative_safeStringCompositingView
{
    // @"WKCompositingView"
    static NSString *string = nil;
    if ([self bdNative_isEmptyString:string]) {
        string = @"WKCompositingView";
    }
    return string;
}

- (BOOL)bdNative_isEqual:(CGFloat)cgf1 withFloat:(CGFloat)cgf2
{
    return fabs(cgf1 - cgf2) > 0.001 ? NO : (fabs(cgf2 - cgf1) > 0.001 ? NO : YES);
}

- (BOOL)bdNative_calNativeViewByIndex:(NSInteger)index scrollView:(UIScrollView *)scrollView
{
    UIView *superview = scrollView.superview;
    if ([superview isKindOfClass:NSClassFromString([self bdNative_safeStringCompositingView])]) {
        // 发现 WKComponsitionView 的第一个layer是背景色的layer。专门用于显示背景的。
        // id 就是这个layer的背景色。
        // 适配iPad的时候发现会出现首个layer无背景色，所以改成遍历
        for (CALayer *layer in superview.layer.sublayers) {
            if (layer.backgroundColor) {
                const CGFloat *components = CGColorGetComponents(layer.backgroundColor);
                BOOL alphaSign = [self bdNative_isEqual:0.13 withFloat:components[3]];
                BOOL redSign = [self bdNative_isEqual:13 withFloat:components[0]*255];
                if (alphaSign && redSign) {  // 如果是 ‘00’， 系统优化就不会渲染了，所以写成01。
                    NSInteger curID = components[1] * 255 * 255 + components[2] * 255;
                    if (index == curID) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

#pragma mark - helper method


- (void)bdNativeWebInvoke:(nonnull NSString *)tagId
             functionName:(nullable NSString *)functionName
                   params:(nullable NSDictionary *)params
                 callback:(nullable id)callback {
    void(^operationBlock)(void) = ^{
        NSString *script = [NSString stringWithFormat:@"window.byted_mixrender_web.invoke(%d, '%@', '%@', %@)", [tagId intValue], functionName, [params bdNative_JSONRepresentation]? :@"{}", callback ? : @""];
        [self evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            
        }];
    };
    if ([NSThread isMainThread]) {
        operationBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            operationBlock();
        });
    }
}

- (void)bdNativeWebInvoke:(NSInteger)callbackId
                   params:(nullable NSDictionary *)params {
    void(^operationBlock)(void) = ^{
        NSString *script = [NSString stringWithFormat:@"window.byted_mixrender_web.callback(%d, '%@')", (int)callbackId, [params bdNative_JSONRepresentation]? :@"{}"];
        [self evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            
        }];
    };
    if ([NSThread isMainThread]) {
        operationBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            operationBlock();
        });
    }
}

- (void)bdNativeEnableNewHandleTouchInvalid:(BOOL)enable
{
    self.bdNative_enableNewHandleTouchInvalid = [NSNumber numberWithBool:enable];
}

- (BOOL)bdNative_calNativeEnableNewHandleTouchInvalid
{
    if (self.bdNative_enableNewHandleTouchInvalid.boolValue == YES)
    {
        return YES;
    }
    
    if ([self.URL.query containsString:@"bdn_enable_new_handle_touch_invalid=1"])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark -- BDNativeWebComponentLogicDelegate
- (WKWebView *)bdNative_nativeComponentWebView
{
    return self;
}

- (void)bdNative_attachWebScrollViewByIndex:(NSInteger)index tryCount:(NSInteger)trycount scrollContentWidth:(NSInteger)scrollContentWidth completion:(nonnull void (^)(UIScrollView *scrollView,  NSError * _Nullable ))completion
{
    static NSInteger kMaxTryCount = 20;
    trycount = trycount > kMaxTryCount ? kMaxTryCount : trycount;
    UIScrollView *scrollView = [self bdNative_findScrollViews:self.scrollView index:index scrollContentWidth:scrollContentWidth];
    if (scrollView) {
        scrollView.scrollEnabled = NO;
        scrollView.bdNativeDisableScroll = YES;
        if (completion) {
            completion(scrollView, nil);
        }
    } else if (--trycount > 0) {
        __weak typeof(self)weakSelf = self;
        // 因为dom的渲染时机不确定，所以需要有一个重试的机制。
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((kMaxTryCount - trycount) * 4 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [weakSelf bdNative_attachWebScrollViewByIndex:index tryCount:trycount scrollContentWidth:scrollContentWidth completion:completion];
        });
    } else {
        if (completion) {
            completion(nil, nil);
        }
    }
}

- (UIView *)bdNativeHitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.bdNative_webViewObject.componentLogic == nil)
    {
        // 如果没有启用native，就不走hook流程
        return [self bdNativeHitTest:point withEvent:event];
    }
    else
    {
        // 背景：在iOS以上按钮的点击事件失效了，借鉴小程序处理手势的解决方案https://study-tech.bytedance.net/articles/13785#heading10
        if ([self bdNative_calNativeEnableNewHandleTouchInvalid]) {
            if(@available(iOS 13.0, *)) self.bdn_touchActionGestureRecognizer.enabled = YES;
        }

        UIView *ret = [self bdNativeHitTest:point withEvent:event];
        if (![ret isKindOfClass:[UIScrollView class]])
        {
            return ret;
        }
        
        BDNativeWebContainerObject *nativeObject = nil;
        for (BDNativeWebContainerObject *object in self.bdNative_webViewObject.componentLogic.containerObjects.allValues)
        {
            if (object.scrollView == ret)
            {
                nativeObject = object;
            }
        }
        
        if(nativeObject.containerView)
        {
            CGPoint pt = [self convertPoint:point toView:nativeObject.scrollView];
            UIView *nativeView = [nativeObject.containerView hitTest:pt withEvent:event];
            
            if ([self bdNative_calNativeEnableNewHandleTouchInvalid]) {
                if (@available(iOS 13.0, *)) self.bdn_touchActionGestureRecognizer.enabled = NO;
            }else{
                if (@available(iOS 13.0, *)) {
                    if ([nativeView isKindOfClass:[UIControl class]]) {;
                        UIControl *control = (UIControl *)nativeView;
                        if (control.bdNative_nativeStateTag) {
                            [control sendActionsForControlEvents:(control.allControlEvents & UIControlEventAllTouchEvents)];
                        }
                        control.bdNative_nativeStateTag = (control.bdNative_nativeStateTag) ? nil : @1;
                    }
                }
            }

            if (nativeView) {
                ret = nativeView;
            }
        }
        return ret;
    }
}

- (void)setBdn_touchActionGestureRecognizer:(UIGestureRecognizer *)bdn_touchActionGestureRecognizer
{
    objc_setAssociatedObject(self, @selector(bdn_touchActionGestureRecognizer), bdn_touchActionGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIGestureRecognizer *)bdn_touchActionGestureRecognizer
{
    UIGestureRecognizer *touchActionGesture = objc_getAssociatedObject(self, @selector(bdn_touchActionGestureRecognizer));
    if (!touchActionGesture) {
        UIView *contentView = [self bdn_findWebContentView:self];
        for (UIGestureRecognizer *gesture in contentView.gestureRecognizers) {
            if ([gesture isKindOfClass:NSClassFromString(BDNSafeStringTouchActionGestureRecognizer())]) {
                self.bdn_touchActionGestureRecognizer = gesture;
                touchActionGesture = gesture;
            }
        }
    }
    return touchActionGesture;
}

- (UIView *)bdn_findWebContentView:(UIView *)view
{
    if ([view isKindOfClass:NSClassFromString(BDNSafeStringContentView())]) {
        return view;
    }
    
    for (UIView *subView in view.subviews) {
        UIView *ret = [self bdn_findWebContentView:subView];
        if (ret) return ret;
    }
    return nil;
}

FOUNDATION_STATIC_INLINE NSString *BDNSafeStringContentView()
{
    // @"WKContentView"
    static NSString *string = nil;
    if (string.length == 0) {
        string = @"WKContentView";
    }
    return string;
}

FOUNDATION_STATIC_INLINE NSString *BDNSafeStringTouchActionGestureRecognizer()
{
    // @"WKTouchActionGestureRecognizer"
    static NSString *string = nil;
    if (string.length == 0) {
        string = @"WKTouchActionGestureRecognizer";
    }
    return string;
}


@end
