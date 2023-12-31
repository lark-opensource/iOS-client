//
//  NSObject+BDXBridgeContainer.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXBridge;

@interface NSObject (BDXBridgeContainer)

- (BDXBridge *)bdx_bridge;
- (void)bdx_setUpBridgeWithContainerID:(NSString *)containerID;
- (void)bdx_tearDownBridge;
- (NSString *)bdx_containerID;

@end

NS_ASSUME_NONNULL_END
