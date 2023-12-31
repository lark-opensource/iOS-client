//
//  JSWorkerBridge.m
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import "JSWorkerBridge.h"

@interface JSWorkerBridge ()

@property(nonatomic, strong) NSMutableArray<id<JSWorkerBridgeExecutor>> *executors;

@end

@implementation JSWorkerBridge

- (NSArray<id<JSWorkerBridgeExecutor>> *)executors {
  if (!_executors) {
    _executors = NSMutableArray.array;
  }
  return _executors;
}

- (void)executeMethodWithMessage:(JSWorkerBridgeReceivedMessage *)message
                        callback:(JSModuleCallbackBlock)callback {
    [self.executors enumerateObjectsUsingBlock:^(id<JSWorkerBridgeExecutor> _Nonnull obj,
                                                 NSUInteger idx, BOOL *_Nonnull stop) {
        __block BOOL processed = NO;
        processed = [obj executeMethodWithMessage:message onBridge:self callback:^(JSWorkerBridgeStatusCode code, NSDictionary * _Nullable data) {
            JSWorkerBridgeSendMessage *callbackMessage = [JSWorkerBridgeSendMessage
                                                        messageWithContainerID:message.containerID];
            callbackMessage.invokeMessage = message;
            callbackMessage.data = data;
            callbackMessage.code = code;
            if (callback) {
                callback(callbackMessage.encodedMessage);
            }
            *stop = processed;
        }];
    }];
}

- (void)addExecutor:(id<JSWorkerBridgeExecutor>)executor {
    @synchronized(self.executors) {
        [self.executors addObject:executor];
        [self.executors sortUsingComparator:^NSComparisonResult(id<JSWorkerBridgeExecutor> obj1,
                                                                id<JSWorkerBridgeExecutor> obj2) {
            NSUInteger priority1 = 0;
            NSUInteger priority2 = 0;
            
            if ([obj1 respondsToSelector:@selector(priority)]) {
                priority1 = obj1.priority;
            }
            
            if ([obj2 respondsToSelector:@selector(priority)]) {
                priority2 = obj2.priority;
            }
            return priority1 > priority2 ? NSOrderedAscending : NSOrderedDescending;
        }];
    }
}

@end
