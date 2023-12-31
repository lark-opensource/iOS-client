//
//  WKWebView+BDNativeWebBridge.h
//  Pods
//
//  Created by liuyunxuan on 2019/7/8.
//

#import <WebKit/WebKit.h>
#import "BDNativeWebBridgeManager.h"
#import "BDNativeWebMessageHandler.h"

@interface WKWebView (BDNativeBridge) <BDNativeWebMessageHandlerDelegate,BDNativeWebBridgeManagerDelegate>

- (void)bdNativeBridge_enableBDNativeBridge;

- (void)bdNativeBridge_registerHandler:(BDNativeBridgeHandler)handler bridgeName:(NSString *)bridgeName;
@end
