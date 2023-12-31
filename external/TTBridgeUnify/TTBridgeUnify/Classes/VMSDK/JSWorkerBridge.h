//
//  JSWorkerBridge.h
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import <Foundation/Foundation.h>
#import "JSWorkerBridgeMessage.h"
#import <vmsdk/jsb/iOS/framework/JSModule.h>
#import "JSWorkerBridgeDefines.h"

NS_ASSUME_NONNULL_BEGIN

@class JSWorkerBridge;

@protocol JSWorkerBridgeExecutor <NSObject>

- (BOOL)executeMethodWithMessage:(JSWorkerBridgeReceivedMessage *)message
                        onBridge:(JSWorkerBridge *)bridge
                        callback:(JSWorkerBridgeCallback)callback;

@optional
- (NSInteger)priority;

@end

@class JSWorkerBridge;


@interface JSWorkerBridge : NSObject

- (void)executeMethodWithMessage:(JSWorkerBridgeReceivedMessage *)message
                         callback:(JSModuleCallbackBlock)callback;

- (void)addExecutor:(id<JSWorkerBridgeExecutor>)executor;

@end

NS_ASSUME_NONNULL_END
