//
//  FixWKWebView.m
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/5/6.
//

#import "FixWKWebView.h"
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>
#import "NSObject+RuntimeExtension.h"
#import <objc/message.h>
#import <objc/runtime.h>

@implementation FixWKWebView

+(BOOL)isWebViewDeallocating:(WKWebView *)webView {
    BOOL (*allowsWeakReference)(id, SEL) =
    (BOOL(*)(id, SEL))class_getMethodImplementation(
                                                    [webView class],
                                                    @selector(allowsWeakReference)
                                                    );
    if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
        BOOL deallocating = !(*allowsWeakReference)(webView, @selector(allowsWeakReference));
        // 尝试修复webView在deallocating中被赋值给weak指针的问题
        if (deallocating) {
            return YES;
            
        }
    }
    return NO;
}

@end

@implementation NSObject (LKFixWKWebView)

+(void)lk_tryFixWKReloadFrameErrorRecoveryAttempter {
    // 尝试修复该问题 https://bytedance.feishu.cn/docx/doxcnZdghcxyA5AOXsdLlVWJSnd
    // 尝试修复 webView 在 deallocating 中被赋值给 weak 指针导致 crash 的问题
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [LarkWebViewLogHelper info:@"FixWKReloadFrameErrorRecoveryAttempter"];
        // WKReloadFrameErrorRecoveryAttempter
        Class instanceClass = NSClassFromString(@"WKReloadFrameErrorRecoveryAttempter");
        // initWithWebView:frameHandle:urlString:
        SEL orig = NSSelectorFromString(@"initWithWebView:frameHandle:urlString:");
        [instanceClass lkw_swizzleOriginClassMethod:orig withHookClassMethod:@selector(lk_fix_initAttempter:frameHandle:urlString:)];
    });
}

-(id)lk_fix_initAttempter:(WKWebView *)webView frameHandle:(void *)frameHandle urlString:(void*)urlString {
    __unsafe_unretained WKWebView *tmpWebView = webView;
    if ([FixWKWebView isWebViewDeallocating:webView]) {
        [LarkWebViewLogHelper info:@"lk_fix_initAttempter isWebViewDeallocating true"];
        tmpWebView = nil;
    }
    return [self lk_fix_initAttempter:tmpWebView frameHandle:frameHandle urlString:urlString];
}

@end
