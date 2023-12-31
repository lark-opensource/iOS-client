//
//  JSWorkerBridgeMessage.m
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import "JSWorkerBridgeMessage.h"

NSString *const JSWorkerBridgeStatusMessageKey = @"__status_message__";

@interface JSWorkerBridgeReceivedMessage ()

@property(nonatomic, strong) NSString *containerID;

@end

@implementation JSWorkerBridgeReceivedMessage

- (instancetype)initWithMethodName:(NSString *)methodName rawData:(NSDictionary *)rawData containerID:(NSString*)containerID {
  self = [super init];
  if (self) {
    _methodName = methodName;
    _rawData = rawData;
    _containerID = containerID;
    [self decode];
  }
  return self;
}

- (void)decode {
  _data = _rawData[@"data"];
  _namescope = _rawData[@"namespace"];
  _protocolVersion = _rawData[@"protocolVersion"] ?: @"1.0.0";  // 默认1.0.0
}

@end

@implementation JSWorkerBridgeSendMessage

+ (instancetype)messageWithContainerID:(NSString *)containerID {
    JSWorkerBridgeSendMessage *message = [[JSWorkerBridgeSendMessage alloc] init];
    message.code = JSWorkerBridgeCodeSucceed;
  message.containerID = containerID;
  return message;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _code = JSWorkerBridgeCodeSucceed;
  }
  return self;
}

- (void)setData:(id)data {
  if ([data isKindOfClass:NSDictionary.class]) {
      _statusDescription = data[JSWorkerBridgeStatusMessageKey];
    data = ({
      NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:data];
      dict[JSWorkerBridgeStatusMessageKey] = nil;
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


