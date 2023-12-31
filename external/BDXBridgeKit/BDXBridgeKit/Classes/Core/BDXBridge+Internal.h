//
//  BDXBridge+Internal.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/14.
//

#import "BDXBridge.h"
#import "BDXBridgeDefinitions.h"
#import "BDXBridgeMacros.h"

NS_ASSUME_NONNULL_BEGIN

// Macro for registering internal global methods.
#define BDX_BRIDGE_INTERNAL_METHODS_SECTION "XBMInternal"
#define bdx_bridge_register_internal_global_method(method) \
    bdx_bridge_register_global_method(method, BDX_BRIDGE_INTERNAL_METHODS_SECTION)

// Macro for registering default global methods.
#define BDX_BRIDGE_DEFAULT_METHODS_SECTION "XBMDefault"
#define bdx_bridge_register_default_global_method(method) \
    bdx_bridge_register_global_method(method, BDX_BRIDGE_DEFAULT_METHODS_SECTION)

@class BDXBridgeMethod;
@class BDXBridgeEvent;
@protocol BDXBridgeContainerProtocol;

@interface BDXBridge (Internal)

- (instancetype)initWithContainer:(id<BDXBridgeContainerProtocol>)container;

/// Send event with event name and params to FE side.
/// @param event The event object to be sent.
/// @note Use `-[BDXBridgeEventCenter.sharedCenter publishEvent:]`
///       if you want the event to go through the 'subscribe-and-publish' model.
- (void)fireEvent:(BDXBridgeEvent *)event;

- (NSDictionary<NSString *, BDXBridgeMethod *> *)mergedMethodsForEngineType:(BDXBridgeEngineType)engineType;

@end

NS_ASSUME_NONNULL_END
