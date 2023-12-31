//
//  BDLynxBridgeMessage.m
//
//  Created by li keliang on 2020/2/9.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "BDLynxBridgeMessage.h"
#import <objc/runtime.h>

NSString *const BDLynxBridgeStatusMessageKey = @"__status_message__";
static NSString *const kUesUIThreadKey = @"useUIThread";

@implementation BDLynxBridgeReceivedMessage

- (instancetype)initWithMethodName:(NSString *)methodName rawData:(NSDictionary *)rawData {
  self = [super init];
  if (self) {
    _methodName = methodName;
    _rawData = rawData;
    [self decode];
  }
  return self;
}

- (void)decode {
  _data = _rawData[@"data"];
  _namescope = _rawData[@"namespace"];
  _containerID = _rawData[@"containerID"];
  _protocolVersion = _rawData[@"protocolVersion"] ?: @"1.0.0";  // 默认1.0.0
  _isDefaultOfUseUIThread = NO;
  if ([_data isKindOfClass:[NSDictionary class]] && [_data objectForKey:kUesUIThreadKey]) {
    _useUIThread = [_data[kUesUIThreadKey] boolValue];
  } else if ([_rawData objectForKey:kUesUIThreadKey]) {
    _useUIThread = [_rawData[kUesUIThreadKey] boolValue];
  } else {
    _useUIThread = YES;
    _isDefaultOfUseUIThread = YES;
  }
}

- (void)useUIThreadDisable {
  _useUIThread = NO;
}

@end

@implementation BDLynxBridgeSendMessage

+ (instancetype)messageWithContainerID:(NSString *)containerID {
  BDLynxBridgeSendMessage *message = [[BDLynxBridgeSendMessage alloc] init];
  message.code = BDLynxBridgeCodeSucceed;
  message.containerID = containerID;
  return message;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _code = BDLynxBridgeCodeSucceed;
  }
  return self;
}

- (void)setData:(id)data {
  if ([data isKindOfClass:NSDictionary.class]) {
    _statusDescription = data[BDLynxBridgeStatusMessageKey];
    data = ({
      NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:data];
      dict[BDLynxBridgeStatusMessageKey] = nil;
      [dict copy];
    });
  }
  _data = data;
}

#pragma mark - Public Methods

- (NSDictionary *)encodedMessage {
  NSMutableDictionary *encodedMessage = [NSMutableDictionary new];
  encodedMessage[@"code"] = @(self.code);
  encodedMessage[@"msg"] = self.statusDescription;
  encodedMessage[@"data"] = self.data;
  encodedMessage[@"containerID"] = self.containerID;
  encodedMessage[@"protocolVersion"] = @"1.1.0";
  return encodedMessage;
}

@end

@implementation BDLynxBridgeReceivedMessage (Error)

- (NSDictionary *)paramsError:(NSString *)errorMessage {
  BDLynxBridgeSendMessage *message =
      [BDLynxBridgeReceivedMessage errorSendMessageWith:errorMessage containerID:self.containerID];
  return message.encodedMessage;
}

+ (BDLynxBridgeSendMessage *)errorSendMessageWith:(NSString *)errorMessage
                                      containerID:(NSString *)containerID {
  BDLynxBridgeSendMessage *message = [BDLynxBridgeSendMessage messageWithContainerID:containerID];
  message.code = BDLynxBridgeCodeParameterError;
  message.data = @{@"message" : errorMessage ?: @""};
  return message;
}

- (NSDictionary *)noHandlerError {
  BDLynxBridgeSendMessage *message =
      [BDLynxBridgeReceivedMessage noHandleErrorMessage:self.containerID];
  return message.encodedMessage;
}

+ (BDLynxBridgeSendMessage *)noHandleErrorMessage:(NSString *)containerID {
  BDLynxBridgeSendMessage *message = [BDLynxBridgeSendMessage messageWithContainerID:containerID];
  message.code = BDLynxBridgeCodeNoHandler;
  return message;
}

@end
