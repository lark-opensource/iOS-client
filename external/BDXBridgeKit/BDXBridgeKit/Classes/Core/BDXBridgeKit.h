//
//  BDXBridgeKit.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import <Foundation/Foundation.h>
#import "BDXBridge.h"
#import "BDXBridgeMacros.h"
#import "BDXBridgeMethod.h"
#import "BDXBridgeContext.h"
#import "BDXBridgeDefinitions.h"
#import "BDXBridgeServiceManager.h"

// Containers/Web
#if __has_include("WKWebView+BDXBridgeContainer.h")
#import "WKWebView+BDXBridgeContainer.h"
#endif

// Containers/RN
#if __has_include("RCTRootView+BDXBridgeContainer.h")
#import "RCTRootView+BDXBridgeContainer.h"
#endif

// Containers/Lynx
#if __has_include("LynxView+BDXBridgeContainer.h")
#import "LynxView+BDXBridgeContainer.h"
#endif

// Engines/TTBridgeUnifyAdapter
#if __has_include("BDXBridgeEngineAdapter_TTBridgeUnify.h")
#import "BDXBridgeEngineAdapter_TTBridgeUnify.h"
#endif
