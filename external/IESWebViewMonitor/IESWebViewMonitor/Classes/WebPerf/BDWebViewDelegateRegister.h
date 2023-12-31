//
//  BDWebViewDelegateRegister.h
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WKWebView, WKNavigation;

typedef NS_ENUM (NSInteger, WebViewNavigationTime) {
    RequestStart,
    RequestFail,
    RedirectStart,
    NavigationStart,
    NavigationPreFinish,
    NavigationFinish,
    NavigationFail
};

@interface BDWebViewDelegateRegister : NSObject

+ (void)insertIMP2WKSetNavigationDelegate:(IMP)imp forCls:(Class)cls;

+ (void)registerWKBlock:(void(^)(WKWebView *wkWebView, id navigation, NSError *error))block
                forTime:(WebViewNavigationTime)time
               forClass:(Class)cls;

+ (void)startMonitorWithClasses:(NSSet *)classes
    onlyMonitorNavigationFinish:(BOOL)onlyMonitorNavigationFinish;

@end

NS_ASSUME_NONNULL_END
