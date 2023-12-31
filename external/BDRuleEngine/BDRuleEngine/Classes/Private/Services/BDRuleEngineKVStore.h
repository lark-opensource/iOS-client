//
//  BDRuleEngineKVStore.h
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineKVStore : NSObject

+ (BOOL)setString:(NSString * _Nullable)value
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID;

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID;

+ (nullable NSString *)stringForKey:(NSString * _Nonnull)key
                           uniqueID:(NSString * _Nullable)uniqueID;

+ (nullable id)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID;

+ (void)removeValueForKey:(NSString *_Nullable)key
                 uniqueID:(NSString * _Nullable)uniqueID;

+ (BOOL)containsKey:(NSString *_Nonnull)key
           uniqueID:(NSString * _Nullable)uniqueID;

+ (nullable NSArray *)allKeysWithUniqueID:(NSString * _Nullable)uniqueID;

+ (void)clearAllWithUniqueID:(NSString * _Nullable)uniqueID;

+ (void)closeWithUniqueID:(NSString * _Nullable)uniqueID;

@end

NS_ASSUME_NONNULL_END
