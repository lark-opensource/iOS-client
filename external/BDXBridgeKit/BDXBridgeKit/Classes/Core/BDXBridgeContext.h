//
//  BDXBridgeContext.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Builtin context keys used to retrieve some additional informations.
extern NSString * const BDXBridgeContextContainerKey;   // Store the container instance of type `id<BDXBridgeContainerProtocol>` on which the bridge instance is mounted.

@interface BDXBridgeContext : NSObject <NSCopying>

- (void)setWeakObject:(id)object forKey:(NSString *)key;
- (void)setStrongObject:(id)object forKey:(NSString *)key;

// Supporting accessing the object via subscript, e.x. `self.context[BDXBridgeContextContainerKey]`.
- (nullable id)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
