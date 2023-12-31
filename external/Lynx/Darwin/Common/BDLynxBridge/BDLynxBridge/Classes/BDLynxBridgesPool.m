//
//  BDLynxBridgesPool.m
//  BDLynxBridge
//
//  Created by li keliang on 2020/3/8.
//

#import "BDLynxBridgesPool.h"
#import "BDLynxBridge+Internal.h"
#import "LynxThreadSafeDictionary.h"

@interface BDLynxBridgesPool ()

@property(atomic, strong) LynxThreadSafeDictionary<NSString *, BDLynxBridge *> *bridgesMap;

@end

@implementation BDLynxBridgesPool : NSObject

+ (instancetype)sharedPool {
  static BDLynxBridgesPool *pool;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pool = [BDLynxBridgesPool new];
    pool.bridgesMap = [LynxThreadSafeDictionary dictionary];
  });
  return pool;
}

#pragma mark - Public Methods

+ (BDLynxBridge *_Nullable)bridgeForContainerID:(NSString *)containerID {
  return [BDLynxBridgesPool.sharedPool.bridgesMap objectForKey:containerID];
}

+ (void)setBridge:(BDLynxBridge *_Nullable)bridge forContainerID:(NSString *)containerID {
  if (bridge == nil) {
    [BDLynxBridgesPool.sharedPool.bridgesMap removeObjectForKey:containerID];
  } else {
    [BDLynxBridgesPool.sharedPool.bridgesMap setObject:bridge forKey:containerID];
  }
}

// Deprecated. bridgesEnumerator must be used in main thread.
+ (NSEnumerator<BDLynxBridge *> *)bridgesEnumerator {
  return BDLynxBridgesPool.sharedPool.bridgesMap.objectEnumerator;
}

+ (void)enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block {
  [BDLynxBridgesPool.sharedPool.bridgesMap enumerateKeysAndObjectsUsingBlock:block];
}

@end
