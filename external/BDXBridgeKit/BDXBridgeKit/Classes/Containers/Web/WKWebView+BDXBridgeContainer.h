//
//  WKWebView+BDXBridgeContainer.h
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import <WebKit/WebKit.h>
#import "BDXBridgeContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (BDXBridgeContainer) <BDXBridgeContainerProtocol>

@end

NS_ASSUME_NONNULL_END
