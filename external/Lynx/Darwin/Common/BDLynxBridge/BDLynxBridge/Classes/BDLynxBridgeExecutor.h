//
//  BDLynxBridgeExecutor.h
//  BDLynxBridge
//
//  Created by li keliang on 2020/4/2.
//

#import <Foundation/Foundation.h>
#import "BDLynxBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class BDLynxBridgeReceivedMessage, BDLynxBridge;
@protocol BDLynxBridgeExecutor <NSObject>

- (BOOL)executeMethodWithMessage:(BDLynxBridgeReceivedMessage *)message
                        onBridge:(BDLynxBridge *)bridge
                        callback:(BDLynxBridgeCallback)callback;

@optional
- (NSInteger)priority;

@end

NS_ASSUME_NONNULL_END
