#import "WKScriptMessage+BDPWebViewFixCrash.h"
#import "BDPWebView.h"
#import <ECOInfra/EMAFeatureGating.h>
#import <objc/runtime.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <objc/message.h>
//  ⚠️免责声明：尝试修复[WKScriptMessage _initWithBody:webView:frameInfo:name:world:]Crash，请注意，本次修复人不是导致Crash的罪魁祸首（和本次Crash没有任何关系），只是对WebView较为熟悉，尝试进行修复，并不承担导致本次Crash的任何责任
void BDPWebViewClassSwizzle(Class cls, SEL orSel, SEL swSel) {
    Method orMethod = class_getInstanceMethod(cls, orSel);
    Method swMethod = class_getInstanceMethod(cls, swSel);
    BOOL didAdd = class_addMethod(cls, orSel, method_getImplementation(swMethod), method_getTypeEncoding(swMethod));
    if (didAdd) {
        class_replaceMethod(cls, swSel, method_getImplementation(orMethod), method_getTypeEncoding(orMethod));
    } else {
        method_exchangeImplementations(orMethod, swMethod);
    }
}

@implementation WKScriptMessage (BDPWebViewFixCrash)
//  ⚠️免责声明：尝试修复[WKScriptMessage _initWithBody:webView:frameInfo:name:world:]Crash，请注意，本次修复人不是导致Crash的罪魁祸首（和本次Crash没有任何关系），只是对WebView较为熟悉，尝试进行修复，并不承担导致本次Crash的任何责任
//  ⚠️code from BDWebKit & BDWebCore
//  ⚠️参考 https://slardar.bytedance.net/node/app_detail/?aid=1378&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/1378_ff1840a0a143693a6917772e213a0a03?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1620799440%2C%22end_time%22%3A1621404240%2C%22granularity%22%3A86400%2C%22event_index%22%3A1%7D
//  参考 https://cony.bytedance.net/code/detail/3321517/1142/49517/changes
+ (void)bdpwebview_tryFixWKScriptMessageCrash {
    //  如果修复稳定，预计4.4下掉FG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 14, *)) {
            SEL orig = NSSelectorFromString(@"_initWithBody:webView:frameInfo:name:world:");
            BDPWebViewClassSwizzle(self, orig, @selector(bdpwebview_fix_scriptMessageBody:webView:frameInfo:name:world:));
        }
        else {
            SEL orig = NSSelectorFromString(@"_initWithBody:webView:frameInfo:name:");
            BDPWebViewClassSwizzle(self, orig, @selector(bdpwebview_fix_scriptMessageBody:webView:frameInfo:name:));
        }
    });
}
- (instancetype)bdpwebview_fix_scriptMessageBody:(id)body webView:(WKWebView *)webView frameInfo:(WKFrameInfo *)frameInfo name:(NSString *)name world:(id)world {
    //  https://slardar.bytedance.net/node/app_detail/?aid=1378&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/1378_73017a91f5bb6e1436d1efd3420ecdbe?params=%7B%22end_time%22%3A1649329668%2C%22start_time%22%3A1648724868%2C%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22event_index%22%3A12%2C%22shortCutKey%22%3A%22last_seven_days%22%7D
    BOOL enableFixCrash = [webView isKindOfClass:BDPWebView.class] || [webView isKindOfClass:LarkWebView.class];

    if (enableFixCrash) {
        BOOL (*allowsWeakReference)(id, SEL) = (BOOL(*)(id, SEL))class_getMethodImplementation([webView class], @selector(allowsWeakReference));
        __unsafe_unretained WKWebView *tmpWebView = webView;
        if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
            BOOL deallocating = !(*allowsWeakReference)(webView, @selector(allowsWeakReference));
            // 尝试修复webView在deallocating中被赋值给weak指针的问题

            if (deallocating) {
                //  走到这里代表马上崩溃了，要导致事故了，但是及时的把tmpWebView设置为nil，尝试避免Crash
                tmpWebView = nil;
                if ([webView isKindOfClass:BDPWebView.class]) {
                    OPMonitorEvent *fixCrashEvent = BDPMonitorWithName(@"gadget_try_fix_webview_wkscriptmessage_crash", ((BDPWebView *)webView).uniqueID);
                    fixCrashEvent.kv(@"name", name?name:@"");
                    fixCrashEvent.flush();
                }
                BDPLogInfo(@"webview dealloc crash name %@ webView type %@", name, NSStringFromClass([webView class]));
            }
        }
        return [self bdpwebview_fix_scriptMessageBody:body webView:tmpWebView frameInfo:frameInfo name:name world:world];
    }
    //  ⚠️走到这里代表原来该怎么走就怎么走，并不会增加任何其他代码，也不会导致Crash，不承担任何系统导致的Crash的任何责任
    return [self bdpwebview_fix_scriptMessageBody:body webView:webView frameInfo:frameInfo name:name world:world];
}
- (instancetype)bdpwebview_fix_scriptMessageBody:(id)body webView:(WKWebView *)webView frameInfo:(WKFrameInfo *)frameInfo name:(NSString *)name {
    //  https://slardar.bytedance.net/node/app_detail/?aid=1378&os=iOS&region=cn&lang=zh#/abnormal/detail/crash/1378_73017a91f5bb6e1436d1efd3420ecdbe?params=%7B%22end_time%22%3A1649329668%2C%22start_time%22%3A1648724868%2C%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22event_index%22%3A12%2C%22shortCutKey%22%3A%22last_seven_days%22%7D

    BOOL enableFixCrash = [webView isKindOfClass:BDPWebView.class] || [webView isKindOfClass:LarkWebView.class];
    if (enableFixCrash) {
        BOOL (*allowsWeakReference)(id, SEL) = (BOOL(*)(id, SEL))class_getMethodImplementation([webView class], @selector(allowsWeakReference));
        __unsafe_unretained WKWebView *tmpWebView = webView;
        if (allowsWeakReference && (IMP)allowsWeakReference != _objc_msgForward) {
            BOOL deallocating = !(*allowsWeakReference)(webView, @selector(allowsWeakReference));
            
            // 尝试修复webView在deallocating中被赋值给weak指针的问题
            if (deallocating) {
                //  走到这里代表马上崩溃了，要导致事故了，但是及时的把tmpWebView设置为nil，尝试避免Crash
                tmpWebView = nil;
                if ([webView isKindOfClass:BDPWebView.class]) {
                    OPMonitorEvent *fixCrashEvent = BDPMonitorWithName(@"gadget_try_fix_webview_wkscriptmessage_crash", ((BDPWebView *)webView).uniqueID);
                    fixCrashEvent.kv(@"name", name?name:@"");
                    fixCrashEvent.flush();
                }

                BDPLogInfo(@"webview dealloc crash name %@ webView type %@", name, NSStringFromClass([webView class]));
            }
        }
        return [self bdpwebview_fix_scriptMessageBody:body webView:tmpWebView frameInfo:frameInfo name:name];
    }
    //  ⚠️走到这里代表原来该怎么走就怎么走，并不会增加任何其他代码，也不会导致Crash，不承担任何系统导致的Crash的任何责任
    return [self bdpwebview_fix_scriptMessageBody:body webView:webView frameInfo:frameInfo name:name];
}
@end
