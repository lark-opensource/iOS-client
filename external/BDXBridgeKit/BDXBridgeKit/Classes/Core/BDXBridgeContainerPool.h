//
//  BDXBridgeContainerPool.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXBridgeContainerProtocol;

@interface BDXBridgeContainerPool : NSObject

@property (class, nonatomic, strong, readonly) BDXBridgeContainerPool *sharedPool;

// Supporting accessing the object via subscript,
// e.x. `BDXBridgeContainerPool.sharedPool[containerID]`.
- (void)setObject:(nullable id<BDXBridgeContainerProtocol>)object forKeyedSubscript:(NSString *)key;
- (nullable id<BDXBridgeContainerProtocol>)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
