//
//  IESFastBridge_Deprecated.h
//  IESWebKit
//
//  Created by li keliang on 2019/4/7.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "IESBridgeEngine_Deprecated.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESFastBridge_Deprecated : NSObject

+ (void)injectionBridgeIntoWKWebView:(WKWebView *)webView;
+ (void)injectionBridge:(IESBridgeEngine_Deprecated *)bridgeEngine intoWKWebView:(WKWebView *)webView;

@end

@interface WKWebView (IESFastBridge_Deprecated)

@property (nonatomic, readonly, nullable) IESBridgeEngine_Deprecated *iesFastBridge;

@end

NS_ASSUME_NONNULL_END
