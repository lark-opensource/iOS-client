//
//  ACCCacheProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/26.
//

#import <Foundation/Foundation.h>
#import "ACCServiceLocator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCacheProtocol <NSObject>

@optional

#pragma mark - basic methods

- (nullable id)objectForKey:(nonnull NSString *)key;

- (void)setObject:(nullable id<NSCoding>)value forKey:(nonnull NSString *)key;

- (void)removeObjectForKey:(nonnull NSString *)key;

- (void)removeAllObjects;

#pragma mark - read cache

- (nullable NSString *)stringForKey:(nonnull NSString *)key;

- (nullable NSArray *)arrayForKey:(nonnull NSString *)key;

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(nonnull NSString *)key;

- (NSInteger)integerForKey:(nonnull NSString *)key;

- (float)floatForKey:(nonnull NSString *)key;

- (double)doubleForKey:(nonnull NSString *)key;

- (BOOL)boolForKey:(nonnull NSString *)key;

- (nullable NSData *)dataForKey:(nonnull NSString *)key;

#pragma mark - write cache

- (void)setInteger:(NSInteger)value forKey:(nonnull NSString *)key;

- (void)setFloat:(float)value forKey:(nonnull NSString *)key;

- (void)setDouble:(double)value forKey:(nonnull NSString *)key;

- (void)setBool:(BOOL)value forKey:(nonnull NSString *)key;

- (void)setString:(nullable NSString *)string forKey:(nonnull NSString *)key;

- (void)setArray:(nullable NSArray *)array forKey:(nonnull NSString *)key;

- (void)setDictionary:(nullable NSDictionary *)dictionary forKey:(nonnull NSString *)key;

@end

FOUNDATION_STATIC_INLINE id<ACCCacheProtocol> ACCCache() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCCacheProtocol)];
}


NS_ASSUME_NONNULL_END
