//
//  BDLynxBridgeListenerManager+Internal.h
//  BDLynxBridge
//
//  Created by bytedance on 2020/6/19.
//

#import "BDLynxBridgeListenerManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBridgeListenerManager (Internal)

+ (void)notifyWillCallEvent:(nullable BDLynxBridge *)lynxBridge
                    message:(nonnull BDLynxBridgeSendMessage *)message;
+ (void)notifyDidCallEvent:(nullable BDLynxBridge *)lynxBridge
                   message:(nonnull BDLynxBridgeSendMessage *)message;

+ (void)notifyWillHandleMethod:(nullable BDLynxBridge *)lynxBridge
                       message:(nonnull BDLynxBridgeReceivedMessage *)message;
+ (void)notifyDidHandleMethod:(nullable BDLynxBridge *)lynxBridge
                      message:(nonnull BDLynxBridgeReceivedMessage *)message;

+ (void)notifyWillCallback:(nullable BDLynxBridge *)lynxBridge
                   message:(nonnull BDLynxBridgeSendMessage *)message;
+ (void)notifyDidCallback:(nullable BDLynxBridge *)lynxBridge
                  message:(nonnull BDLynxBridgeSendMessage *)message;

@end

NS_ASSUME_NONNULL_END
