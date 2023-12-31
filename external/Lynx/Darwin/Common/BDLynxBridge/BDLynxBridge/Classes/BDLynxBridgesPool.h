//
//  BDLynxBridgesPool.h
//  BDLynxBridge
//
//  Created by li keliang on 2020/3/8.
//

#import <Foundation/Foundation.h>
@class BDLynxBridge;

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxBridgesPool : NSObject

// Deprecated. Don't use bridgesEnumerator, it can cause multi-thread problem. Use
// enumerateKeysAndObjectsUsingBlock instead.
@property(nonatomic, strong, class, readonly) NSEnumerator<BDLynxBridge *> *bridgesEnumerator
    __attribute__((deprecated("Don't use bridgesEnumerator, it can cause multi-thread problem. Use "
                              "enumerateKeysAndObjectsUsingBlock instead.")));

+ (BDLynxBridge *_Nullable)bridgeForContainerID:(NSString *)containerID;

+ (void)setBridge:(BDLynxBridge *_Nullable)bridge forContainerID:(NSString *)containerID;

+ (void)enumerateKeysAndObjectsUsingBlock:(void(NS_NOESCAPE ^)(id key, id obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
