#import "WKWebView+LKWMonitorCatefory.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>
static char kHasLoadRequestMonitorKey;
void LKWMonitorCateforyWKWebViewClassSwizzle(Class cls, SEL orSel, SEL swSel) {
    Method orMethod = class_getInstanceMethod(cls, orSel);
    Method swMethod = class_getInstanceMethod(cls, swSel);
    BOOL didAdd = class_addMethod(cls, orSel, method_getImplementation(swMethod), method_getTypeEncoding(swMethod));
    if (didAdd) {
        class_replaceMethod(cls, swSel, method_getImplementation(orMethod), method_getTypeEncoding(orMethod));
    } else {
        method_exchangeImplementations(orMethod, swMethod);
    }
}
@implementation WKWebView (LKWMonitorCatefory)
+ (void)lkwm_setupLKWMonitorCatefory {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL origi = @selector(initWithFrame:configuration:);
        LKWMonitorCateforyWKWebViewClassSwizzle(self, origi, @selector(lkw_monitor_initWithFrame:configuration:));
        SEL origl = @selector(loadRequest:);
        LKWMonitorCateforyWKWebViewClassSwizzle(self, origl, @selector(lkw_monitor_loadRequest:));
    });
}
- (instancetype)lkw_monitor_initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKWebView *w = [self lkw_monitor_initWithFrame:frame configuration:configuration];
    [WKWebViewMonitor webviewInitMonitorWithClassName:NSStringFromClass(w.class) ?: @""];
    return w;
}
- (nullable WKNavigation *)lkw_monitor_loadRequest:(NSURLRequest *)request {
    NSString *host = request.URL.host;
    if (host && host.length != 0) {
        NSString *reported = objc_getAssociatedObject(self, &kHasLoadRequestMonitorKey);
        if (!reported) {
            [WKWebViewMonitor webviewLoadRequestMonitorWithClassName:NSStringFromClass(self.class) ?: @"" host:host ?: @""];
            objc_setAssociatedObject(self, &kHasLoadRequestMonitorKey, @"hasMonitor", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return [self lkw_monitor_loadRequest:request];
}
@end
