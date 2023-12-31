//
//  WKWebView+IESBridgeExecutor.h
//  IESWebKit
//
//  Created by li keliang on 2019/10/10.
//

#import <WebKit/WebKit.h>
#import <IESJSBridgeCore/IESBridgeEngine.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (IESBridgeExecutor) <IESBridgeExecutor>

- (IESBridgeEngine *)ies_bridgeEngine;

@end

NS_ASSUME_NONNULL_END
