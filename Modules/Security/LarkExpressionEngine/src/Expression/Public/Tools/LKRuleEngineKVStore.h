//
//  LKRuleEngineKVStore.h
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/8/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LKRuleEngineKVStore : NSObject

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID;

+ (nullable id)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID;

@end

NS_ASSUME_NONNULL_END
