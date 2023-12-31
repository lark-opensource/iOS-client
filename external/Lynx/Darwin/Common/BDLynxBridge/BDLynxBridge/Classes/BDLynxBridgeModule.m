//
//  BDLynxBridgeModule.m
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "BDLynxBridgeModule.h"
#import "BDLynxBridge+Internal.h"
#import "BDLynxBridgeListenerManager+Internal.h"
#import "BDLynxBridgeListenerManager.h"
#import "BDLynxBridgeMessage.h"
#import "LynxLog.h"

@interface BDLynxBridgeModule ()

@property(nonatomic, strong) NSString *containerID;

@end

@implementation BDLynxBridgeModule

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
  return @{@"call" : NSStringFromSelector(@selector(call:params:callback:))};
}

+ (NSString *)name {
  return @"bridge";
}

- (instancetype)initWithParam:(NSDictionary *)param {
  self = [super init];
  if (self) {
    _containerID = param[@"containerID"];
  }
  return self;
}

#pragma mark -

- (void)call:(NSString *)name params:(NSDictionary *)params callback:(LynxCallbackBlock)callback {
  BDLynxBridgeReceivedMessage *message =
      [[BDLynxBridgeReceivedMessage alloc] initWithMethodName:name rawData:params];

  NSString *containerID = message.containerID.length > 0 ? message.containerID : self.containerID;

  BDLynxBridge *bridge = [BDLynxBridgesPool bridgeForContainerID:containerID];
  if (bridge) {
    [bridge _executeMethodWithMessage:message callback:callback];
  } else {
    LLogError(@"BDLynxBridge error: can not find bridge for container id: %@", containerID);
    BDLynxBridgeSendMessage *errorMsg =
        [BDLynxBridgeReceivedMessage errorSendMessageWith:@"error container id"
                                              containerID:message.containerID];
    errorMsg.invokeMessage = message;
    [BDLynxBridgeListenerManager notifyWillCallback:nil message:errorMsg];
    if (callback != nil) {
      callback(errorMsg.encodedMessage);
    }
    [BDLynxBridgeListenerManager notifyDidCallback:nil message:errorMsg];
  }
}

@end
