//
//  BDLynxBridgeListenerManager.h
//  BDLynxBridge
//
//  Created by bytedance on 2020/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDLynxBridge;
@class BDLynxBridgeSendMessage;
@class BDLynxBridgeReceivedMessage;

@protocol BDLynxBridgeListenerDelegate <NSObject>

- (void)lynxBridge:(BDLynxBridge *)lynxBridge willCallEvent:(BDLynxBridgeSendMessage *)message;
- (void)lynxBridge:(BDLynxBridge *)lynxBridge didCallEvent:(BDLynxBridgeSendMessage *)message;

- (void)lynxBridge:(BDLynxBridge *)lynxBridge
    willHandleMethod:(BDLynxBridgeReceivedMessage *)message;
- (void)lynxBridge:(BDLynxBridge *)lynxBridge
    didHandleMethod:(BDLynxBridgeReceivedMessage *)message;

- (void)lynxBridge:(BDLynxBridge *)lynxBridge willCallback:(BDLynxBridgeSendMessage *)message;
- (void)lynxBridge:(BDLynxBridge *)lynxBridge didCallback:(BDLynxBridgeSendMessage *)message;

@end

@interface BDLynxBridgeListenerManager : NSObject

+ (void)addBridgeListener:(id<BDLynxBridgeListenerDelegate>)listener;

@end

NS_ASSUME_NONNULL_END
