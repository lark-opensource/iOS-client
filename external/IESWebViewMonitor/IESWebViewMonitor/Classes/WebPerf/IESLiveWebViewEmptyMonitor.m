//
//  IESLiveWebViewEmptyMonitor.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/7/16.
//

#import "IESLiveWebViewEmptyMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "BDWebViewDelegateRegister.h"
#import "IESLiveMonitorUtils.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "BDHybridMonitorDefines.h"

static NSMutableDictionary<Class, NSMutableDictionary<NSString*, NSValue*>*> *ORIGEmptyImpDic = nil;
static NSMutableArray *wkWebViewClsesOnMonitor = nil;


static void prepareDicForClass(Class cls) {
    if (![ORIGEmptyImpDic objectForKey:cls]) {
        ORIGEmptyImpDic[(id<NSCopying>)cls] = [[NSMutableDictionary alloc] init];
    }
}

@interface WKWebView (IESWebViewEmptyMonitor)
@end

@implementation WKWebView (IESWebViewEmptyMonitor)

- (void)addRenderEventListener {
    NSString *selStr = [NSString stringWithFormat:@"%@%@%@", @"_setOb", @"servedRendering", @"ProgressEvents:"];
    SEL sel = NSSelectorFromString(selStr);
    IMP imp = [[self class] instanceMethodForSelector:sel];
    NSMethodSignature *signature = [self methodSignatureForSelector:sel];
    if (signature && imp) {
        ((void(*)(WKWebView*, SEL, int))imp)(self, sel, 0xffff);
    }
}

@end

@implementation IESLiveWebViewEmptyMonitor

+ (void)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting {
    if (![setting[kBDWMEmptyMonitor] boolValue]) {
        return;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ORIGEmptyImpDic = [NSMutableDictionary dictionary];
        wkWebViewClsesOnMonitor = [NSMutableArray array];
    });
    for (Class cls in classes) {
        if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
            if ([wkWebViewClsesOnMonitor containsObject:cls]) {
                continue;
            }
            prepareDicForClass(cls);
            [wkWebViewClsesOnMonitor addObject:cls];
        }
    };
}

+ (void)stopMonitor {
    
}

+ (void)addObserverToWKWebView:(WKWebView *)wkWebView {
    if ([wkWebViewClsesOnMonitor containsObject:wkWebView.class]) {
        [wkWebView addRenderEventListener];
    }
}

@end
