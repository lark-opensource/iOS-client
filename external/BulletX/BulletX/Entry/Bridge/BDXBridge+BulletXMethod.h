//
//  BDXBridge+BulletXMethod.h
//  Bullet-Pods-Aweme
//
//  Created by bill on 2020/12/6.
//

#import <BDXBridgeKit/BDXBridge.h>
#import <BDXBridgeKit/BDXBridgeMethod.h>

@class BDXBridgeContext;

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridge (BulletXMethod)

+ (NSArray<NSString *> *)bdx_bulletAutoRegisteredMethods;

- (void)bdx_bulletAutoRegisterMethodsWithContext:(nullable BDXBridgeContext *)context;

@end

NS_ASSUME_NONNULL_END
