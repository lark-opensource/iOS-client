//
//  TTWebViewBridgeEngine.h
//  NewsInHouse
//
//  Created by lizhuopeng on 2018/10/23.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "TTBridgeEngine.h"
#import "TTBridgeAuthorization.h"
#import "TTBridgeRegister.h"

NS_ASSUME_NONNULL_BEGIN

@class TTWebViewBridgeEngine;



@interface WKWebView (TTBridge)

@property (nonatomic, strong, readonly) TTWebViewBridgeEngine *tt_engine;

- (void)tt_installBridgeEngine:(TTWebViewBridgeEngine *)bridge;
- (void)tt_uninstallBridgeEngine;

@end

@interface TTWebViewBridgeEngine : NSObject<TTBridgeEngine>

@property (nonatomic, weak, readonly, nullable) UIViewController *sourceController;

@property (nonatomic, strong, readonly, nullable) NSURL *sourceURL;

@property (nonatomic, weak, readonly) NSObject *sourceObject;


- (void)installOnWKWebView:(WKWebView *)webView;
- (void)uninstallFromWKWebView:(WKWebView *)webView;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(nullable void (^)(id result, NSError *error))completionHandler;

+ (void)postEventNotification:(TTBridgeName)bridgeName params:(nullable NSDictionary *)params;
+ (void)postEventNotification:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString *))resultBlock;

// Default authorization is [TTBridgeAuthManager sharedManager].
- (instancetype)initWithAuthorization:(id<TTBridgeAuthorization>)authorization;

@property (nonatomic, strong) id<TTBridgeAuthorization> authorization;

@property(nonatomic, strong, readonly) TTBridgeRegister *bridgeRegister;

@property(nonatomic, weak, readonly, nullable) WKWebView *wkWebView;


/// When this property is YES, bytedance://dispatch_message will be Intercepted. And it is YES by default.
@property(nonatomic, assign) BOOL schemaInterceptionEnabled;

@property(nonatomic, strong, class, readonly) NSHashTable *webViewEngines;

@end
NS_ASSUME_NONNULL_END
