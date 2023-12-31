//
//  WKWebView+BDXBridgeContainer.m
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import "WKWebView+BDXBridgeContainer.h"
#import "NSObject+BDXBridgeContainer.h"

@implementation WKWebView (BDXBridgeContainer)

- (BDXBridgeEngineType)bdx_engineType
{
    return BDXBridgeEngineTypeWeb;
}

@end
