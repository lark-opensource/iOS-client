//
//  BDXGlobalContext.h
//  TTLynx
//
//  Created by LinFeng on 2021/4/20.
//

#import <Foundation/Foundation.h>
#import "BDXContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXGlobalContext : NSObject

+ (void)registerWeakObj:(nullable id)obj forType:(Class)aClass withBid:(nullable NSString *)bid;
+ (void)registerStrongObj:(nullable id)obj forType:(Class)aClass withBid:(nullable NSString *)bid;
;
+ (void)registerCopyObj:(nullable id<NSCopying>)obj forType:(Class)aClass withBid:(nullable NSString *)bid;
+ (void)registerWeakObj:(nullable id)obj forKey:(NSString *)key withBid:(nullable NSString *)bid;
+ (void)registerStrongObj:(nullable id)obj forKey:(NSString *)key withBid:(nullable NSString *)bid;
+ (void)registerCopyObj:(nullable id<NSCopying>)obj forKey:(NSString *)key withBid:(nullable NSString *)bid;
+ (nullable id)getObjForType:(Class)aClass withBid:(nullable NSString *)bid;
+ (nullable id)getObjForKey:(NSString *)key withBid:(nullable NSString *)bid;
+ (BOOL)isWeakObjForKey:(NSString *)key withBid:(nullable NSString *)bid;

/// Just merge, will not overwrite the global value
+ (BDXContext *)mergeContext:(BDXContext *)context withBid:(nullable NSString *)bid;

@end

NS_ASSUME_NONNULL_END
