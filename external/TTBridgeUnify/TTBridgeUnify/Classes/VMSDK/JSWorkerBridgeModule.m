//
//  JSWorkerBridgeModule.m
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import "JSWorkerBridgeModule.h"
#import "JSWorkerBridgeMessage.h"
#import "JSWorkerBridge.h"
#import "JSWorkerBridgePool.h"

@interface JSWorkerBridgeModule ()

@property (nonatomic,strong) NSString* containerID;
@property (nonatomic,strong) JSWorkerBridge* bridge;

@end

@implementation JSWorkerBridgeModule

- (instancetype)initWithParam:(id)param{
  if (self = [super init]) {
      if([param isKindOfClass:[NSDictionary class]]){
          self.containerID = param[@"containerID"];
          if(self.containerID){
              self.bridge = [JSWorkerBridgePool bridgeForContainerID:self.containerID];
          }
      }
  }
  return self;
}

- (void)dealloc {
    [JSWorkerBridgePool unregisterBridgeForContainerID:self.containerID];
}

+ (NSString *)name {
  return @"bridge";
}

+ (NSDictionary<NSString *, NSString *> *)methodLookup {
    return @{@"call" : NSStringFromSelector(@selector(call:params:callback:))};
}

- (void)call:(NSString *)name params:(NSDictionary *)params callback:(JSModuleCallbackBlock)callback {
    JSWorkerBridgeReceivedMessage *message = [[JSWorkerBridgeReceivedMessage alloc] initWithMethodName:name rawData:params containerID:self.containerID];
    [self.bridge executeMethodWithMessage:message callback:callback];
}


@end
