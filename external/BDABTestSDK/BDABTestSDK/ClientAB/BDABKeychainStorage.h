//
//  BDABKeychainStorage.h
//  BDABTestSDK
//
//  Created by July22 on 2019/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDABKeychainStorage : NSObject

- (instancetype)initWithServiceName:(NSString *)serviceName useUserDefaultCache:(BOOL)useUserDefaultCache;

- (nullable id)objectForKey:(NSString *)key;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

- (BOOL)hasObjectForKey:(NSString *)key;

- (BOOL)removeAll;

@end

NS_ASSUME_NONNULL_END
