//
//  BDLynxBridgeMethod.m
//  BDLynxBridge
//
//  Created by li keliang on 2020/3/8.
//

#import "BDLynxBridgeMethod.h"

@implementation BDLynxBridgeMethod

- (instancetype)initWithMethodName:(NSString *)methodName
                           handler:(BDLynxBridgeHandler)handler
                    sessionHandler:(BDLynxBridgeSessionHandler)sessionHandler
                         namescope:(NSString *)namescope {
  self = [super init];
  if (self) {
    _methodName = methodName;
    _handler = handler;
    _sessionHandler = sessionHandler;
    _namescope = namescope ?: BDLynxBridgeDefaultNamescope;
  }
  return self;
}

@end
