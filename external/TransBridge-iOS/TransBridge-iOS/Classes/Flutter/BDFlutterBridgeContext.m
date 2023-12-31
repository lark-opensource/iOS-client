//
//  FLTBridgeContext.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/7.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDFlutterBridgeContext.h"
#import "BDMethodProtocol.h"
#import "BDFLTBResponse.h"
#import "BDBridgeHost.h"

@interface BDFlutterBridgeContext()

@property (weak , nonatomic) NSObject *messager;

@end

@implementation BDFlutterBridgeContext

- (instancetype)initWithMessage:(NSObject *)messager {
  if (self = [super init]) {
      self.messager = messager;
  }
  return self;
}

- (void)sendEvent:(NSString *)name data:(id)data {
  [[BDBridgeHost getHostByCarrier:self.messager] sendEvent:name data:data];
}

#pragma mark - BridgeContext

- (NSObject *)messager {
  return _messager;
}

- (BridgeContextType)contextType {
  return BridgeContextTypeFlutter;
}

@end
