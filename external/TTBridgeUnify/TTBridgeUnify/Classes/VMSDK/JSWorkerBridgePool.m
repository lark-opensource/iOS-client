//
//  JSWorkerBridgePool.m
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import "JSWorkerBridgePool.h"

@interface JSWorkerBridgePool ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, JSWorkerBridge *> *bridgesMap;

@end

@implementation JSWorkerBridgePool : NSObject

+ (instancetype)sharedPool {
  static JSWorkerBridgePool *pool;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pool = [JSWorkerBridgePool new];
    pool.bridgesMap = [NSMutableDictionary dictionary];
  });
  return pool;
}

#pragma mark - Public Methods

+ (JSWorkerBridge *_Nullable)bridgeForContainerID:(NSString *)containerID {
  @synchronized(JSWorkerBridgePool.sharedPool) {
    return [JSWorkerBridgePool.sharedPool.bridgesMap objectForKey:containerID];
  }
}

+ (void)registerBridge:(JSWorkerBridge *_Nullable)bridge forContainerID:(NSString *)containerID {
  @synchronized(JSWorkerBridgePool.sharedPool) {
      JSWorkerBridgePool.sharedPool.bridgesMap[containerID] = bridge;
  }
}

+ (void)unregisterBridgeForContainerID:(NSString *)containerID {
    @synchronized(JSWorkerBridgePool.sharedPool) {
        [JSWorkerBridgePool.sharedPool.bridgesMap removeObjectForKey:containerID];
    }
}

@end
