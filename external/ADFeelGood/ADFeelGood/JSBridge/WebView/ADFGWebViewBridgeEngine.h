//
//  ADFGWebViewBridgeEngine.h
//  NewsInHouse
//
//  Created by iCuiCui on 2020/04/23.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ADFGBridgeEngine.h"
#import "ADFGBridgeRegister.h"

NS_ASSUME_NONNULL_BEGIN

@class ADFGWebViewBridgeEngine;
@class ADFGWKWebView;

@protocol ADFGWKWebViewDelegate <NSObject>

@optional
- (void)webViewDidStartLoad:(ADFGWKWebView *)webView;

- (void)webViewDidFinishLoad:(ADFGWKWebView *)webView;

- (void)webView:(ADFGWKWebView *)webView didFailLoadWithError:(NSError *)error;

@end

@interface ADFGWKWebView : WKWebView

@property (nonatomic, strong, readonly) ADFGWebViewBridgeEngine *adfg_engine;

@property (nonatomic, weak) id<ADFGWKWebViewDelegate> slaveDelates;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (void)adfg_installBridgeEngine:(ADFGWebViewBridgeEngine *)bridge;
- (void)adfg_uninstallBridgeEngine;

@end

@interface ADFGWebViewBridgeEngine : NSObject<ADFGBridgeEngine,WKScriptMessageHandler>

@property (nonatomic, weak, nullable) UIViewController *sourceController;

@property (nonatomic, strong, readonly, nullable) NSURL *sourceURL;

@property(nonatomic, weak, readonly, nullable) ADFGWKWebView *wkWebView;

- (instancetype)initWithBridgeRegister:(ADFGBridgeRegister *)bridgeRegister;

- (void)installOnWKWebView:(ADFGWKWebView *)webView;
- (void)uninstallFromWKWebView:(ADFGWKWebView *)webView;

// on
- (void)fireEvent:(ADFGBridgeName)eventName params:(nullable NSDictionary *)params;
- (void)fireEvent:(ADFGBridgeName)eventName params:(nullable NSDictionary *)params resultBlock:(void (^)(NSString * _Nullable))resultBlock;
- (void)fireEvent:(ADFGBridgeName)eventName msg:(ADFGBridgeMsg)msg callbackID:(NSString *)callbackID params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock;

// call
- (void)registerBridge:(void(^)(ADFGBridgeRegisterMaker *maker))block;
- (void)unregisterBridge:(ADFGBridgeName)bridgeName;
- (BOOL)respondsToBridge:(ADFGBridgeName)bridgeName;

@end
NS_ASSUME_NONNULL_END
