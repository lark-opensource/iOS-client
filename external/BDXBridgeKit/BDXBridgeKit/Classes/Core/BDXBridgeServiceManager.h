//
//  BDXBridgeServiceManager.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/1/13.
//

#import <Foundation/Foundation.h>
#import "BDXBridgeServiceDefinitions.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - BDXBridgeServiceManager

#define bdx_bind_service(c, p) [BDXBridgeServiceManager.sharedManager bindProtocl:NSProtocolFromString(@#p) toClass:NSClassFromString(@#c)]
#define bdx_get_service(p) BDXBridgeServiceManager.sharedManager[@protocol(p)]

@interface BDXBridgeServiceManager : NSObject

@property (class, nonatomic, strong, readonly) BDXBridgeServiceManager *sharedManager;

- (void)bindProtocl:(Protocol *)protocol toClass:(Class)klass;

// Supporting accessing the object via subscript,
// e.x. `BDXBridgeServiceManager.sharedManager[@protocol(BDXBridgeNetworkServiceProtocol)]`.
- (nullable id)objectForKeyedSubscript:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
